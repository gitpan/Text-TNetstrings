#include <math.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

const STRLEN INIT_SIZE = 32;

enum tn_type {
	tn_type_array      = ']',
	tn_type_bool       = '!',
	tn_type_bytestring = ',',
	tn_type_float      = '^',
	tn_type_hash       = '}',
	tn_type_integer    = '#',
	tn_type_null       = '~',
};

struct tn_buffer {
	SV *sv;
	size_t size;
	char *start;
	char *cursor;
};

static void tn_encode(SV *data, struct tn_buffer *buf);
static void tn_encode_array(SV *data, struct tn_buffer *buf);
static void tn_encode_hash(SV *data, struct tn_buffer *buf);
/* Initialize structure */
static int tn_buffer_init(struct tn_buffer *buf, size_t size);
/* Prepend character at the beginning of the buffer */
static int tn_buffer_putc(struct tn_buffer *buf, char);
/* Prepend string at the beginning of the buffer */
static int tn_buffer_puts(struct tn_buffer *buf, char *str, STRLEN len);
/* Prepend number at the beginning of the buffer */
static int tn_buffer_puti(struct tn_buffer *buf, size_t i);
/* Allocate enough memory to accomodate an additional n bytes */
static int tn_buffer_expand(struct tn_buffer *buf, size_t n);
/* Return the length of the buffer */
static STRLEN tn_buffer_length(struct tn_buffer *buf);
/* Finalize the buffer and return the resulting scalar. This will move
 * the string from the end of the buffer to the beginning, resulting in
 * a "normal" string.
 *
 * If len is not null it will be set to the length of the resulting
 * string.
 *
 * The buffer becomes invalid.
 */
static SV *tn_buffer_finalize(struct tn_buffer *buf, STRLEN *len);
/* Free the structure */
static void tn_buffer_free(struct tn_buffer *buf);

static void
tn_encode(SV *data, struct tn_buffer *buf)
{
	size_t init_length = tn_buffer_length(buf) + 1;

	/* Null */
	if(!SvOK(data)) {
		tn_buffer_puts(buf, "0:~", 3);
		return;
	}
	/* Integer */
	else if(SvIOK(data)) {
		tn_buffer_putc(buf, tn_type_integer);
		tn_buffer_puts(buf, SvPV_nolen(data), strlen(SvPV_nolen(data)));
	}
	/* Floating point */
	else if(SvNOK(data)) {
		tn_buffer_putc(buf, tn_type_float);
		tn_buffer_puts(buf, SvPV_nolen(data), strlen(SvPV_nolen(data)));
	}
	/* String */
	else if(SvPOK(data)) {
		tn_buffer_putc(buf, tn_type_bytestring);
		tn_buffer_puts(buf, SvPV_nolen(data), strlen(SvPV_nolen(data)));
	}
	/* Reference (Hash/Array) */
	else if(SvROK(data)) {
		data = SvRV(data);
		switch(SvTYPE(data)) {
			case SVt_PVAV:
				tn_buffer_putc(buf, tn_type_array);
				tn_encode_array(data, buf);
				break;
			case SVt_PVHV:
				tn_buffer_putc(buf, tn_type_hash);
				tn_encode_hash(data, buf);
				break;
			default:
				croak("encountered %s (%s), but TNetstrings can only represent references to arrays or hashes",
					SvPV_nolen(data), sv_reftype(data, 0));
		}
	} else {
		croak("support for type (%s, %s) not implemented, please file a bug",
			sv_reftype(data, 0), SvPV_nolen(data));
	}
	tn_buffer_putc(buf, ':');
	tn_buffer_puti(buf, tn_buffer_length(buf) - init_length - 1);
}

static void
tn_encode_array(SV *data, struct tn_buffer *buf)
{
	AV *array = (AV *)data;
	I32 len = av_len(array) + 1;
	I32 i;

	for(i = len - 1; i >= 0; --i) {
		tn_encode(*av_fetch(array, i, 0), buf);
	}
}

static void
tn_encode_hash(SV *data, struct tn_buffer *buf)
{
	HV *hash = (HV *)data;
	HE *entry;
	SV *key;

	hv_iterinit(hash);
	while(entry = hv_iternext(hash)) {
		key = hv_iterkeysv(entry);
		SvPOK_on(key);
		tn_encode(hv_iterval(hash, entry), buf);
		tn_encode(key, buf);
	}
}

/* The tn_decode function will modify the input string to optimize
 * tokenization.
 *
 * The format of a TNetstring is <length>:<body><type_indicator>. To
 * avoid copying strings, the colon (':') delimiter and type indicator
 * are replaced with a NULL byte. This enables atoi(), strlen(), etc.
 * to work on the embedded strings.
 */
static SV *
tn_decode(char *encoded, char **rest)
{
	SV *decoded = NULL;;
	STRLEN byte_length = 0;
	STRLEN length = 0;
	char *cursor = encoded;
	char *end = NULL;
	enum tn_type type;

	if(*cursor > '9' || '0' > *cursor) {
		croak("expected number but got \"%s\"", cursor);
	}

	/* Find the end of the length field */
	end = strchr(cursor, ':');
	if(end == NULL) {
		croak("expected ':'");
	}
	*end = '\0';
	byte_length = atoi(cursor);
	/* Find boundry of body */
	cursor = end + 1;
	length = strlen(cursor) - 1; /* Ignore type indicator */
	if(byte_length > length) {
		croak("expected %d bytes but got %d: \"%s\"", byte_length, length);
	}
	/* Find and terminate type indicator */
	end = cursor + byte_length;
	type = *end;
	*end = '\0';
	if(rest != NULL) {
		if(length > byte_length) {
			*rest = end + 1;
		} else {
			*rest = NULL;
		}
	}

	/* Everything in between is the body */
	switch(type) {
		case tn_type_array:
			decoded = newRV_noinc((SV *)newAV());
			while(cursor != NULL && cursor <= end) {
				SV *elem = tn_decode(cursor, &cursor);
				if(elem != NULL) {
					av_push((AV *)SvRV(decoded), elem);
				} else {
					croak("expected array element but got \"%s\"", cursor);
				}
			}
			break;
		case tn_type_bool:
			if(strcmp(cursor, "true") == 0) {
				decoded = newSViv(1);
			} else if(strcmp(cursor, "false") == 0) {
				decoded = newSViv(0);
			} else {
				croak("expected \"true\" or \"false\" but got \"%s\"", cursor);
			}
			break;
		case tn_type_float:
			decoded = newSVnv(atof(cursor));
			break;
		case tn_type_hash:
			decoded = newRV_noinc((SV *)newHV()); // TODO
			while(cursor != NULL && cursor <= end) {
				SV *key = tn_decode(cursor, &cursor);
				if(key == NULL) {
					croak("expected hash key but got \"%s\"", cursor);
				} else if(SvROK(key)) {
					croak("hash keys must be strings");
				}
				SV *value = tn_decode(cursor, &cursor);
				if(value == NULL) {
					croak("expected hash value but got \"%s\"", cursor);
				}
				/* Hash takes ownership of value but not key. The value
				 * refcount must be decremented if storing fails. The
				 * key's refcount must always be decremented. */
				if(!hv_store_ent((HV *)SvRV(decoded), key, value, 0)) {
					SvREFCNT_dec(decoded);
				}
				SvREFCNT_dec(key);
			}
			break;
		case tn_type_null:
			decoded = &PL_sv_undef;
			break;
		case tn_type_integer:
			decoded = newSViv(atoi(cursor));
			break;
		case tn_type_bytestring:
			decoded = newSVpvn(cursor, end - cursor);
			break;
		default:
			croak("invalid date type '%c'", type);
	}
	return decoded;
}

static int
tn_buffer_init(struct tn_buffer *buf, size_t size)
{
	assert(buf);
	buf->sv = newSV(size);
	if(!buf->sv) {
		return 0;
	}
	SvPOK_only(buf->sv);
	buf->start = SvPVX(buf->sv);
	buf->cursor = buf->start + size;
	*buf->cursor = '\0';
	buf->size = size;
	return 1;
}

static int
tn_buffer_expand(struct tn_buffer *buf, size_t n)
{
	struct tn_buffer old;
	STRLEN length;
	assert(buf);
	assert(buf->cursor <= buf->start && "buffer overflow");
	if(buf->cursor - buf->start < n) {
		Move(buf, &old, 1, old);
		length = tn_buffer_length(buf);

		buf->size = old.size * 2;
		while(buf->size < old.size + n) {
			buf->size *= 2;
		}

		tn_buffer_init(buf, buf->size);
		buf->cursor = buf->start + buf->size - length;
		Move(old.cursor, buf->cursor, length, *buf->cursor);
		sv_free(old.sv);
	}
}

static STRLEN
tn_buffer_length(struct tn_buffer *buf)
{
	return buf->size - (buf->cursor - buf->start);
}

static int
tn_buffer_putc(struct tn_buffer *buf, char ch)
{
	assert(buf);
	tn_buffer_expand(buf, 1);
	buf->cursor--;
	*buf->cursor = ch;
	return 1;
}

static int
tn_buffer_puti(struct tn_buffer *buf, size_t i)
{
	assert(buf);
	do {
		tn_buffer_putc(buf, (i % 10) + '0');
		i = i / 10;
	} while(i > 0);
	return 1;
}

static int
tn_buffer_puts(struct tn_buffer *buf, char *str, STRLEN len)
{
	assert(buf);
	if(len <= 0) {
		len = strlen(str);
	}
	tn_buffer_expand(buf, len);
	buf->cursor -= len;
	Move(str, buf->cursor, len, *str);
	return len;
}

static SV *
tn_buffer_finalize(struct tn_buffer *buf, STRLEN *len)
{
	size_t length = tn_buffer_length(buf);
	Move(buf->cursor, buf->start, length, *buf->start);
	buf->start[length] = '\0';
	if(len != NULL) {
		*len = length;
	}
	return newSVpvn(buf->start, length);
}

static void
tn_buffer_free(struct tn_buffer *buf)
{
	assert(buf);
	sv_free(buf->sv);
	buf->sv = NULL;
}

/* XSUBS */
MODULE = Text::TNetstrings::XS PACKAGE = Text::TNetstrings::XS PREFIX=TN_

SV *
TN_encode_tnetstrings(data)
	SV *data
	PREINIT:
		struct tn_buffer buffer;
		SV *encoded;
	CODE:
	{
		tn_buffer_init(&buffer, INIT_SIZE);
		tn_encode(data, &buffer);
		encoded = tn_buffer_finalize(&buffer, NULL);
		tn_buffer_free(&buffer);
		RETVAL = encoded;
	}
	OUTPUT:
		RETVAL

SV *
TN_decode_tnetstrings(encoded)
	SV *encoded
	PREINIT:
		SV *sv = NULL;
		char *rest = NULL;
	PPCODE:
	{
		/* tn_decode modifies the input string, so give it a /copy/ of
		 * provided SV */
		sv = newSVsv(encoded);
		SvPOK_only(encoded);
		XPUSHs(sv_2mortal(tn_decode(SvPV_nolen(sv), &rest)));
		sv_free(sv);
		if(rest != NULL) {
			XPUSHs(sv_2mortal(newSVpvn(rest, strlen(rest))));
		}
	}
