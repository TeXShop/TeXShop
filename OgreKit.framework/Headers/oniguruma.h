#ifndef ONIGURUMA_H
#define ONIGURUMA_H
/**********************************************************************
  oniguruma.h - Oniguruma (regular expression library)
**********************************************************************/
/*-
 * Copyright (c) 2002-2005  K.Kosako  <sndgk393 AT ybb DOT ne DOT jp>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#define ONIGURUMA
#define ONIGURUMA_VERSION_MAJOR   3
#define ONIGURUMA_VERSION_MINOR   5
#define ONIGURUMA_VERSION_TEENY   4

#ifdef __cplusplus
# ifndef  HAVE_PROTOTYPES
#  define HAVE_PROTOTYPES 1
# endif
# ifndef  HAVE_STDARG_PROTOTYPES
#  define HAVE_STDARG_PROTOTYPES 1
# endif
#endif

#ifndef P_
#if defined(__STDC__) || defined(_WIN32)
# define P_(args) args
#else
# define P_(args) ()
#endif
#endif

#ifndef PV_
#ifdef HAVE_STDARG_PROTOTYPES
# define PV_(args) args
#else
# define PV_(args) ()
#endif
#endif

#ifndef ONIG_EXTERN
#if defined(_WIN32) && !defined(__GNUC__)
#if defined(EXPORT) || defined(RUBY_EXPORT)
#define ONIG_EXTERN   extern __declspec(dllexport)
#else
#define ONIG_EXTERN   extern __declspec(dllimport)
#endif
#endif
#endif

#ifndef ONIG_EXTERN
#define ONIG_EXTERN   extern
#endif

/* PART: character encoding */

typedef unsigned char  UChar;
typedef unsigned long  OnigCodePoint;
typedef unsigned int   OnigDistance;

#define ONIG_INFINITE_DISTANCE  ~((OnigDistance )0)

/* ambiguous match flag */
#define ONIGENC_AMBIGUOUS_MATCH_NONE                   0
#define ONIGENC_AMBIGUOUS_MATCH_ASCII_CASE            (1<<0)
#define ONIGENC_AMBIGUOUS_MATCH_NONASCII_CASE         (1<<1)
/* #define ONIGENC_AMBIGUOUS_MATCH_ACCENT             (1<<2) */
/* #define ONIGENC_AMBIGUOUS_MATCH_HIRAGANA_KATAKANA  (1<<3) */
/* #define ONIGENC_AMBIGUOUS_MATCH_KATAKANA_WIDTH     (1<<4) */

#define ONIGENC_AMBIGUOUS_MATCH_LIMIT                 (1<<1)
#define ONIGENC_AMBIGUOUS_MATCH_COMPOUND              (1<<30)

#define ONIGENC_AMBIGUOUS_MATCH_FULL \
  ( ONIGENC_AMBIGUOUS_MATCH_ASCII_CASE | \
    ONIGENC_AMBIGUOUS_MATCH_NONASCII_CASE | \
    ONIGENC_AMBIGUOUS_MATCH_COMPOUND )
#define ONIGENC_AMBIGUOUS_MATCH_DEFAULT \
    (ONIGENC_AMBIGUOUS_MATCH_ASCII_CASE | \
     ONIGENC_AMBIGUOUS_MATCH_NONASCII_CASE | \
     ONIGENC_AMBIGUOUS_MATCH_COMPOUND )

typedef unsigned int OnigAmbigType;

#define ONIGENC_MAX_COMP_AMBIG_CODE_LEN       3
#define ONIGENC_MAX_COMP_AMBIG_CODE_ITEM_NUM  4

/* code range */
#define ONIGENC_CODE_RANGE_NUM(range)     ((int )range[0])
#define ONIGENC_CODE_RANGE_FROM(range,i)  range[((i)*2) + 1]
#define ONIGENC_CODE_RANGE_TO(range,i)    range[((i)*2) + 2]

typedef struct {
  int len;
  OnigCodePoint code[ONIGENC_MAX_COMP_AMBIG_CODE_LEN];
} OnigCompAmbigCodeItem;

typedef struct {
  int n;
  OnigCodePoint code;
  OnigCompAmbigCodeItem items[ONIGENC_MAX_COMP_AMBIG_CODE_ITEM_NUM];
} OnigCompAmbigCodes;

typedef struct {
  OnigCodePoint from;
  OnigCodePoint to;
} OnigPairAmbigCodes;

typedef struct {
  OnigCodePoint esc;
  OnigCodePoint anychar;
  OnigCodePoint anytime;
  OnigCodePoint zero_or_one_time;
  OnigCodePoint one_or_more_time;
  OnigCodePoint anychar_anytime;
} OnigMetaCharTableType;


#if defined(RUBY_PLATFORM) && defined(M17N_H)

#define ONIG_RUBY_M17N
typedef m17n_encoding*        OnigEncoding;

#else

typedef struct {
  int    (*mbc_enc_len)(UChar* p);
  const char*   name;
  int           max_enc_len;
  int           min_enc_len;
  OnigAmbigType support_ambig_flag;
  OnigMetaCharTableType meta_char_table;
  int    (*is_mbc_newline)(UChar* p, UChar* end);
  OnigCodePoint (*mbc_to_code)(UChar* p, UChar* end);
  int    (*code_to_mbclen)(OnigCodePoint code);
  int    (*code_to_mbc)(OnigCodePoint code, UChar *buf);
  int    (*mbc_to_normalize)(OnigAmbigType flag, UChar** pp, UChar* end, UChar* to);
  int    (*is_mbc_ambiguous)(OnigAmbigType flag, UChar** pp, UChar* end);
  int    (*get_all_pair_ambig_codes)(OnigAmbigType flag, OnigPairAmbigCodes** acs);
  int    (*get_all_comp_ambig_codes)(OnigAmbigType flag, OnigCompAmbigCodes** acs);
  int    (*is_code_ctype)(OnigCodePoint code, unsigned int ctype);
  int    (*get_ctype_code_range)(int ctype, OnigCodePoint* sb_range[], OnigCodePoint* mb_range[]);
  UChar* (*left_adjust_char_head)(UChar* start, UChar* p);
  int    (*is_allowed_reverse_match)(UChar* p, UChar* end);
} OnigEncodingType;

typedef OnigEncodingType* OnigEncoding;

ONIG_EXTERN OnigEncodingType OnigEncodingASCII;
ONIG_EXTERN OnigEncodingType OnigEncodingISO_8859_1;
ONIG_EXTERN OnigEncodingType OnigEncodingISO_8859_2;
ONIG_EXTERN OnigEncodingType OnigEncodingISO_8859_3;
ONIG_EXTERN OnigEncodingType OnigEncodingISO_8859_4;
ONIG_EXTERN OnigEncodingType OnigEncodingISO_8859_5;
ONIG_EXTERN OnigEncodingType OnigEncodingISO_8859_6;
ONIG_EXTERN OnigEncodingType OnigEncodingISO_8859_7;
ONIG_EXTERN OnigEncodingType OnigEncodingISO_8859_8;
ONIG_EXTERN OnigEncodingType OnigEncodingISO_8859_9;
ONIG_EXTERN OnigEncodingType OnigEncodingISO_8859_10;
ONIG_EXTERN OnigEncodingType OnigEncodingISO_8859_11;
ONIG_EXTERN OnigEncodingType OnigEncodingISO_8859_13;
ONIG_EXTERN OnigEncodingType OnigEncodingISO_8859_14;
ONIG_EXTERN OnigEncodingType OnigEncodingISO_8859_15;
ONIG_EXTERN OnigEncodingType OnigEncodingISO_8859_16;
ONIG_EXTERN OnigEncodingType OnigEncodingUTF8;
ONIG_EXTERN OnigEncodingType OnigEncodingUTF16_BE;
ONIG_EXTERN OnigEncodingType OnigEncodingUTF16_LE;
ONIG_EXTERN OnigEncodingType OnigEncodingUTF32_BE;
ONIG_EXTERN OnigEncodingType OnigEncodingUTF32_LE;
ONIG_EXTERN OnigEncodingType OnigEncodingEUC_JP;
ONIG_EXTERN OnigEncodingType OnigEncodingEUC_TW;
ONIG_EXTERN OnigEncodingType OnigEncodingEUC_KR;
ONIG_EXTERN OnigEncodingType OnigEncodingEUC_CN;
ONIG_EXTERN OnigEncodingType OnigEncodingSJIS;
ONIG_EXTERN OnigEncodingType OnigEncodingKOI8;
ONIG_EXTERN OnigEncodingType OnigEncodingKOI8_R;
ONIG_EXTERN OnigEncodingType OnigEncodingBIG5;

#define ONIG_ENCODING_ASCII        (&OnigEncodingASCII)
#define ONIG_ENCODING_ISO_8859_1   (&OnigEncodingISO_8859_1)
#define ONIG_ENCODING_ISO_8859_2   (&OnigEncodingISO_8859_2)
#define ONIG_ENCODING_ISO_8859_3   (&OnigEncodingISO_8859_3)
#define ONIG_ENCODING_ISO_8859_4   (&OnigEncodingISO_8859_4)
#define ONIG_ENCODING_ISO_8859_5   (&OnigEncodingISO_8859_5)
#define ONIG_ENCODING_ISO_8859_6   (&OnigEncodingISO_8859_6)
#define ONIG_ENCODING_ISO_8859_7   (&OnigEncodingISO_8859_7)
#define ONIG_ENCODING_ISO_8859_8   (&OnigEncodingISO_8859_8)
#define ONIG_ENCODING_ISO_8859_9   (&OnigEncodingISO_8859_9)
#define ONIG_ENCODING_ISO_8859_10  (&OnigEncodingISO_8859_10)
#define ONIG_ENCODING_ISO_8859_11  (&OnigEncodingISO_8859_11)
#define ONIG_ENCODING_ISO_8859_13  (&OnigEncodingISO_8859_13)
#define ONIG_ENCODING_ISO_8859_14  (&OnigEncodingISO_8859_14)
#define ONIG_ENCODING_ISO_8859_15  (&OnigEncodingISO_8859_15)
#define ONIG_ENCODING_ISO_8859_16  (&OnigEncodingISO_8859_16)
#define ONIG_ENCODING_UTF8         (&OnigEncodingUTF8)
#define ONIG_ENCODING_UTF16_BE     (&OnigEncodingUTF16_BE)
#define ONIG_ENCODING_UTF16_LE     (&OnigEncodingUTF16_LE)
#define ONIG_ENCODING_UTF32_BE     (&OnigEncodingUTF32_BE)
#define ONIG_ENCODING_UTF32_LE     (&OnigEncodingUTF32_LE)
#define ONIG_ENCODING_EUC_JP       (&OnigEncodingEUC_JP)
#define ONIG_ENCODING_EUC_TW       (&OnigEncodingEUC_TW)
#define ONIG_ENCODING_EUC_KR       (&OnigEncodingEUC_KR)
#define ONIG_ENCODING_EUC_CN       (&OnigEncodingEUC_CN)
#define ONIG_ENCODING_SJIS         (&OnigEncodingSJIS)
#define ONIG_ENCODING_KOI8         (&OnigEncodingKOI8)
#define ONIG_ENCODING_KOI8_R       (&OnigEncodingKOI8_R)
#define ONIG_ENCODING_BIG5         (&OnigEncodingBIG5)

#endif /* else RUBY && M17N */

#define ONIG_ENCODING_UNDEF    ((OnigEncoding )0)


/* work size */
#define ONIGENC_CODE_TO_MBC_MAXLEN      7
#define ONIGENC_MBC_NORMALIZE_MAXLEN    ONIGENC_CODE_TO_MBC_MAXLEN

/* character types */
#define ONIGENC_CTYPE_NEWLINE  (1<< 0)
#define ONIGENC_CTYPE_ALPHA    (1<< 1)
#define ONIGENC_CTYPE_BLANK    (1<< 2)
#define ONIGENC_CTYPE_CNTRL    (1<< 3)
#define ONIGENC_CTYPE_DIGIT    (1<< 4)
#define ONIGENC_CTYPE_GRAPH    (1<< 5)
#define ONIGENC_CTYPE_LOWER    (1<< 6)
#define ONIGENC_CTYPE_PRINT    (1<< 7)
#define ONIGENC_CTYPE_PUNCT    (1<< 8)
#define ONIGENC_CTYPE_SPACE    (1<< 9)
#define ONIGENC_CTYPE_UPPER    (1<<10)
#define ONIGENC_CTYPE_XDIGIT   (1<<11)
#define ONIGENC_CTYPE_WORD     (1<<12)
#define ONIGENC_CTYPE_ASCII    (1<<13)
#define ONIGENC_CTYPE_ALNUM    (ONIGENC_CTYPE_ALPHA | ONIGENC_CTYPE_DIGIT)

#define enc_len(enc,p)                ONIGENC_MBC_ENC_LEN(enc,p)

#define ONIGENC_IS_UNDEF(enc)          ((enc) == ONIG_ENCODING_UNDEF)
#define ONIGENC_IS_SINGLEBYTE(enc)     (ONIGENC_MBC_MAXLEN(enc) == 1)
#define ONIGENC_IS_MBC_HEAD(enc,p)     (ONIGENC_MBC_ENC_LEN(enc,p) != 1)
#define ONIGENC_IS_MBC_ASCII(p)           (*(p)   < 128)
#define ONIGENC_IS_CODE_ASCII(code)       ((code) < 128)
#define ONIGENC_IS_CODE_SB_WORD(enc,code) \
  (ONIGENC_IS_CODE_ASCII(code) && ONIGENC_IS_CODE_WORD(enc,code))
#define ONIGENC_IS_MBC_WORD(enc,s,end) \
   ONIGENC_IS_CODE_WORD(enc,ONIGENC_MBC_TO_CODE(enc,s,end))


#ifdef ONIG_RUBY_M17N

#include <ctype.h> /* for isblank(), isgraph() */

#define ONIGENC_MBC_TO_NORMALIZE(enc,flag,pp,end,buf) \
        onigenc_mbc_to_normalize(enc,flag,pp,end,buf)
#define ONIGENC_IS_MBC_AMBIGUOUS(enc,flag,pp,end) \
        onigenc_is_mbc_ambiguous(enc,flag,pp,end)

#define ONIGENC_SUPPORT_AMBIG_FLAG(enc)     ONIGENC_AMBIGUOUS_MATCH_ASCII_CASE
#define ONIGENC_IS_ALLOWED_REVERSE_MATCH(enc,s,end) \
        onigenc_is_allowed_reverse_match(enc, s, end)
#define ONIGENC_LEFT_ADJUST_CHAR_HEAD(enc,start,s) \
        onigenc_get_left_adjust_char_head(enc, start, s)
#define ONIGENC_GET_ALL_PAIR_AMBIG_CODES(enc, ambig_flag, acs)    0
#define ONIGENC_GET_ALL_COMP_AMBIG_CODES(enc, ambig_flag, acs)    0
#define ONIGENC_GET_CTYPE_CODE_RANGE(enc,ctype,sbr,mbr) \
        ONIG_NO_SUPPORT_CONFIG
#define ONIGENC_MBC_ENC_LEN(enc,p)            m17n_mbclen(enc,(int )(*p))
#define ONIGENC_MBC_MAXLEN(enc)               m17n_mbmaxlen(enc)
#define ONIGENC_MBC_MAXLEN_DIST(enc) \
    (ONIGENC_MBC_MAXLEN(enc) > 0 ? ONIGENC_MBC_MAXLEN(enc) \
                                 : ONIG_INFINITE_DISTANCE)
#define ONIGENC_MBC_MINLEN(enc)            1
#define ONIGENC_MBC_TO_CODE(enc,p,e)       m17n_codepoint((enc),(p),(e))
#define ONIGENC_CODE_TO_MBCLEN(enc,code)   m17n_codelen((enc),(code))
#define ONIGENC_CODE_TO_MBC(enc,code,buf)  onigenc_code_to_mbc(enc, code, buf)

#if 0     /* !! not supported !! */
#define ONIGENC_IS_MBC_NEWLINE(enc,p,end)
#define ONIGENC_STEP_BACK(enc,start,s,n)
#endif

#define ONIGENC_IS_CODE_CTYPE(enc,code,ctype) \
        onigenc_is_code_ctype(enc,code,ctype)

#ifdef isblank
# define ONIGENC_IS_CODE_BLANK(enc,code) isblank((int )code)
#else
# define ONIGENC_IS_CODE_BLANK(enc,code) ((code) == ' ' || (code) == '\t')
#endif
#ifdef isgraph
# define ONIGENC_IS_CODE_GRAPH(enc,code) isgraph((int )code)
#else
# define ONIGENC_IS_CODE_GRAPH(enc,code) \
  (isprint((int )code) && !isspace((int )code))
#endif

#define ONIGENC_IS_CODE_PRINT(enc,code)     m17n_isprint(enc,code)
#define ONIGENC_IS_CODE_ALNUM(enc,code)     m17n_isalnum(enc,code)
#define ONIGENC_IS_CODE_ALPHA(enc,code)     m17n_isalpha(enc,code)
#define ONIGENC_IS_CODE_LOWER(enc,code)     m17n_islower(enc,code)
#define ONIGENC_IS_CODE_UPPER(enc,code)     m17n_isupper(enc,code)
#define ONIGENC_IS_CODE_CNTRL(enc,code)     m17n_iscntrl(enc,code)
#define ONIGENC_IS_CODE_PUNCT(enc,code)     m17n_ispunct(enc,code)
#define ONIGENC_IS_CODE_SPACE(enc,code)     m17n_isspace(enc,code)
#define ONIGENC_IS_CODE_DIGIT(enc,code)     m17n_isdigit(enc,code)
#define ONIGENC_IS_CODE_XDIGIT(enc,code)    m17n_isxdigit(enc,code)
#define ONIGENC_IS_CODE_WORD(enc,code)      m17n_iswchar(enc,code)

ONIG_EXTERN
int onigenc_is_code_ctype P_((OnigEncoding enc, OnigCodePoint code, int ctype));
ONIG_EXTERN
int onigenc_code_to_mbc P_((OnigEncoding enc, OnigCodePoint code, UChar *buf));
ONIG_EXTERN
int onigenc_mbc_to_normalize P_((OnigEncoding enc, OnigAmbigType flag, UChar** pp, UChar* end, UChar* buf));
ONIG_EXTERN
int onigenc_is_mbc_ambiguous P_((OnigEncoding enc, OnigAmbigType flag, UChar** pp, UChar* end));
ONIG_EXTERN
int onigenc_is_allowed_reverse_match P_((OnigEncoding enc, UChar* s, UChar* end));

#else  /* ONIG_RUBY_M17N */

#define ONIGENC_NAME(enc)                      ((enc)->name)

#define ONIGENC_MBC_TO_NORMALIZE(enc,flag,pp,end,buf) \
        (enc)->mbc_to_normalize(flag,pp,end,buf)
#define ONIGENC_IS_MBC_AMBIGUOUS(enc,flag,pp,end) \
        (enc)->is_mbc_ambiguous(flag,pp,end)
#define ONIGENC_SUPPORT_AMBIG_FLAG(enc)        ((enc)->support_ambig_flag)
#define ONIGENC_IS_ALLOWED_REVERSE_MATCH(enc,s,end) \
        (enc)->is_allowed_reverse_match(s,end)
#define ONIGENC_LEFT_ADJUST_CHAR_HEAD(enc,start,s) \
        (enc)->left_adjust_char_head(start, s)
#define ONIGENC_GET_ALL_PAIR_AMBIG_CODES(enc,ambig_flag,acs) \
        (enc)->get_all_pair_ambig_codes(ambig_flag,acs)
#define ONIGENC_GET_ALL_COMP_AMBIG_CODES(enc,ambig_flag,acs) \
        (enc)->get_all_comp_ambig_codes(ambig_flag,acs)
#define ONIGENC_STEP_BACK(enc,start,s,n) \
        onigenc_step_back((enc),(start),(s),(n))

#define ONIGENC_MBC_ENC_LEN(enc,p)             (enc)->mbc_enc_len(p)
#define ONIGENC_MBC_MAXLEN(enc)               ((enc)->max_enc_len)
#define ONIGENC_MBC_MAXLEN_DIST(enc)           ONIGENC_MBC_MAXLEN(enc)
#define ONIGENC_MBC_MINLEN(enc)               ((enc)->min_enc_len)
#define ONIGENC_IS_MBC_NEWLINE(enc,p,end)      (enc)->is_mbc_newline((p),(end))
#define ONIGENC_MBC_TO_CODE(enc,p,end)         (enc)->mbc_to_code((p),(end))
#define ONIGENC_CODE_TO_MBCLEN(enc,code)       (enc)->code_to_mbclen(code)
#define ONIGENC_CODE_TO_MBC(enc,code,buf)      (enc)->code_to_mbc(code,buf)

#define ONIGENC_IS_CODE_CTYPE(enc,code,ctype)  (enc)->is_code_ctype(code,ctype)

#define ONIGENC_IS_CODE_NEWLINE(enc,code) \
        ONIGENC_IS_CODE_CTYPE(enc,code,ONIGENC_CTYPE_NEWLINE)
#define ONIGENC_IS_CODE_GRAPH(enc,code) \
        ONIGENC_IS_CODE_CTYPE(enc,code,ONIGENC_CTYPE_GRAPH)
#define ONIGENC_IS_CODE_PRINT(enc,code) \
        ONIGENC_IS_CODE_CTYPE(enc,code,ONIGENC_CTYPE_PRINT)
#define ONIGENC_IS_CODE_ALNUM(enc,code) \
        ONIGENC_IS_CODE_CTYPE(enc,code,ONIGENC_CTYPE_ALNUM)
#define ONIGENC_IS_CODE_ALPHA(enc,code) \
        ONIGENC_IS_CODE_CTYPE(enc,code,ONIGENC_CTYPE_ALPHA)
#define ONIGENC_IS_CODE_LOWER(enc,code) \
        ONIGENC_IS_CODE_CTYPE(enc,code,ONIGENC_CTYPE_LOWER)
#define ONIGENC_IS_CODE_UPPER(enc,code) \
        ONIGENC_IS_CODE_CTYPE(enc,code,ONIGENC_CTYPE_UPPER)
#define ONIGENC_IS_CODE_CNTRL(enc,code) \
        ONIGENC_IS_CODE_CTYPE(enc,code,ONIGENC_CTYPE_CNTRL)
#define ONIGENC_IS_CODE_PUNCT(enc,code) \
        ONIGENC_IS_CODE_CTYPE(enc,code,ONIGENC_CTYPE_PUNCT)
#define ONIGENC_IS_CODE_SPACE(enc,code) \
        ONIGENC_IS_CODE_CTYPE(enc,code,ONIGENC_CTYPE_SPACE)
#define ONIGENC_IS_CODE_BLANK(enc,code) \
        ONIGENC_IS_CODE_CTYPE(enc,code,ONIGENC_CTYPE_BLANK)
#define ONIGENC_IS_CODE_DIGIT(enc,code) \
        ONIGENC_IS_CODE_CTYPE(enc,code,ONIGENC_CTYPE_DIGIT)
#define ONIGENC_IS_CODE_XDIGIT(enc,code) \
        ONIGENC_IS_CODE_CTYPE(enc,code,ONIGENC_CTYPE_XDIGIT)
#define ONIGENC_IS_CODE_WORD(enc,code) \
        ONIGENC_IS_CODE_CTYPE(enc,code,ONIGENC_CTYPE_WORD)

#define ONIGENC_GET_CTYPE_CODE_RANGE(enc,ctype,sbr,mbr) \
        (enc)->get_ctype_code_range(ctype,sbr,mbr)

ONIG_EXTERN
UChar* onigenc_step_back P_((OnigEncoding enc, UChar* start, UChar* s, int n));

#endif /* is not ONIG_RUBY_M17N */


/* encoding API */
ONIG_EXTERN
int onigenc_init P_(());
ONIG_EXTERN
int onigenc_set_default_encoding P_((OnigEncoding enc));
ONIG_EXTERN
OnigEncoding onigenc_get_default_encoding P_(());
ONIG_EXTERN
void  onigenc_set_default_caseconv_table P_((UChar* table));
ONIG_EXTERN
UChar* onigenc_get_right_adjust_char_head_with_prev P_((OnigEncoding enc, UChar* start, UChar* s, UChar** prev));
ONIG_EXTERN
UChar* onigenc_get_prev_char_head P_((OnigEncoding enc, UChar* start, UChar* s));
ONIG_EXTERN
UChar* onigenc_get_left_adjust_char_head P_((OnigEncoding enc, UChar* start, UChar* s));
ONIG_EXTERN
UChar* onigenc_get_right_adjust_char_head P_((OnigEncoding enc, UChar* start, UChar* s));
ONIG_EXTERN
int onigenc_strlen P_((OnigEncoding enc, UChar* p, UChar* end));
ONIG_EXTERN
int onigenc_strlen_null P_((OnigEncoding enc, UChar* p));
ONIG_EXTERN
int onigenc_str_bytelen_null P_((OnigEncoding enc, UChar* p));



/* PART: regular expression */

/* config parameters */
#define ONIG_NREGION                          10
#define ONIG_MAX_BACKREF_NUM                1000
#define ONIG_MAX_REPEAT_NUM               100000
#define ONIG_MAX_MULTI_BYTE_RANGES_NUM      1000
/* constants */
#define ONIG_MAX_ERROR_MESSAGE_LEN            90

typedef unsigned int        OnigOptionType;

#define ONIG_OPTION_DEFAULT            ONIG_OPTION_NONE

/* options */
#define ONIG_OPTION_NONE                 0
#define ONIG_OPTION_IGNORECASE           1L
#define ONIG_OPTION_EXTEND               (ONIG_OPTION_IGNORECASE         << 1)
#define ONIG_OPTION_MULTILINE            (ONIG_OPTION_EXTEND             << 1)
#define ONIG_OPTION_SINGLELINE           (ONIG_OPTION_MULTILINE          << 1)
#define ONIG_OPTION_FIND_LONGEST         (ONIG_OPTION_SINGLELINE         << 1)
#define ONIG_OPTION_FIND_NOT_EMPTY       (ONIG_OPTION_FIND_LONGEST       << 1)
#define ONIG_OPTION_NEGATE_SINGLELINE    (ONIG_OPTION_FIND_NOT_EMPTY     << 1)
#define ONIG_OPTION_DONT_CAPTURE_GROUP   (ONIG_OPTION_NEGATE_SINGLELINE  << 1)
#define ONIG_OPTION_CAPTURE_GROUP        (ONIG_OPTION_DONT_CAPTURE_GROUP << 1)
/* options (search time) */
#define ONIG_OPTION_NOTBOL               (ONIG_OPTION_CAPTURE_GROUP << 1)
#define ONIG_OPTION_NOTEOL               (ONIG_OPTION_NOTBOL << 1)
#define ONIG_OPTION_POSIX_REGION         (ONIG_OPTION_NOTEOL << 1)

#define ONIG_OPTION_ON(options,regopt)      ((options) |= (regopt))
#define ONIG_OPTION_OFF(options,regopt)     ((options) &= ~(regopt))
#define ONIG_IS_OPTION_ON(options,option)   ((options) & (option))

/* syntax */
typedef struct {
  unsigned int  op;
  unsigned int  op2;
  unsigned int  behavior;
  OnigOptionType options;    /* default option */
} OnigSyntaxType;

ONIG_EXTERN OnigSyntaxType OnigSyntaxPosixBasic;
ONIG_EXTERN OnigSyntaxType OnigSyntaxPosixExtended;
ONIG_EXTERN OnigSyntaxType OnigSyntaxEmacs;
ONIG_EXTERN OnigSyntaxType OnigSyntaxGrep;
ONIG_EXTERN OnigSyntaxType OnigSyntaxGnuRegex;
ONIG_EXTERN OnigSyntaxType OnigSyntaxJava;
ONIG_EXTERN OnigSyntaxType OnigSyntaxPerl;
ONIG_EXTERN OnigSyntaxType OnigSyntaxRuby;

/* predefined syntaxes (see regsyntax.c) */
#define ONIG_SYNTAX_POSIX_BASIC        (&OnigSyntaxPosixBasic)
#define ONIG_SYNTAX_POSIX_EXTENDED     (&OnigSyntaxPosixExtended)
#define ONIG_SYNTAX_EMACS              (&OnigSyntaxEmacs)
#define ONIG_SYNTAX_GREP               (&OnigSyntaxGrep)
#define ONIG_SYNTAX_GNU_REGEX          (&OnigSyntaxGnuRegex)
#define ONIG_SYNTAX_JAVA               (&OnigSyntaxJava)
#define ONIG_SYNTAX_PERL               (&OnigSyntaxPerl)
#define ONIG_SYNTAX_RUBY               (&OnigSyntaxRuby)

/* default syntax */
ONIG_EXTERN OnigSyntaxType*   OnigDefaultSyntax;
#define ONIG_SYNTAX_DEFAULT   OnigDefaultSyntax

/* syntax (operators) */
#define ONIG_SYN_OP_VARIABLE_META_CHARACTERS    (1<<0)
#define ONIG_SYN_OP_DOT_ANYCHAR                 (1<<1)   /* . */
#define ONIG_SYN_OP_ASTERISK_ZERO_INF           (1<<2)   /* * */
#define ONIG_SYN_OP_ESC_ASTERISK_ZERO_INF       (1<<3)
#define ONIG_SYN_OP_PLUS_ONE_INF                (1<<4)   /* + */
#define ONIG_SYN_OP_ESC_PLUS_ONE_INF            (1<<5)
#define ONIG_SYN_OP_QMARK_ZERO_ONE              (1<<6)   /* ? */
#define ONIG_SYN_OP_ESC_QMARK_ZERO_ONE          (1<<7)
#define ONIG_SYN_OP_BRACE_INTERVAL              (1<<8)   /* {lower,upper} */
#define ONIG_SYN_OP_ESC_BRACE_INTERVAL          (1<<9)   /* \{lower,upper\} */
#define ONIG_SYN_OP_VBAR_ALT                    (1<<10)   /* | */
#define ONIG_SYN_OP_ESC_VBAR_ALT                (1<<11)  /* \| */
#define ONIG_SYN_OP_LPAREN_SUBEXP               (1<<12)  /* (...)   */
#define ONIG_SYN_OP_ESC_LPAREN_SUBEXP           (1<<13)  /* \(...\) */
#define ONIG_SYN_OP_ESC_AZ_BUF_ANCHOR           (1<<14)  /* \A, \Z, \z */
#define ONIG_SYN_OP_ESC_CAPITAL_G_BEGIN_ANCHOR  (1<<15)  /* \G     */
#define ONIG_SYN_OP_DECIMAL_BACKREF             (1<<16)  /* \num   */
#define ONIG_SYN_OP_BRACKET_CC                  (1<<17)  /* [...]  */
#define ONIG_SYN_OP_ESC_W_WORD                  (1<<18)  /* \w, \W */
#define ONIG_SYN_OP_ESC_LTGT_WORD_BEGIN_END     (1<<19)  /* \<. \> */
#define ONIG_SYN_OP_ESC_B_WORD_BOUND            (1<<20)  /* \b, \B */
#define ONIG_SYN_OP_ESC_S_WHITE_SPACE           (1<<21)  /* \s, \S */
#define ONIG_SYN_OP_ESC_D_DIGIT                 (1<<22)  /* \d, \D */
#define ONIG_SYN_OP_LINE_ANCHOR                 (1<<23)  /* ^, $   */
#define ONIG_SYN_OP_POSIX_BRACKET               (1<<24)  /* [:xxxx:] */
#define ONIG_SYN_OP_QMARK_NON_GREEDY            (1<<25)  /* ??,*?,+?,{n,m}? */
#define ONIG_SYN_OP_ESC_CONTROL_CHARS           (1<<26)  /* \n,\r,\t,\a ... */
#define ONIG_SYN_OP_ESC_C_CONTROL               (1<<27)  /* \cx  */
#define ONIG_SYN_OP_ESC_OCTAL3                  (1<<28)  /* \OOO */
#define ONIG_SYN_OP_ESC_X_HEX2                  (1<<29)  /* \xHH */
#define ONIG_SYN_OP_ESC_X_BRACE_HEX8            (1<<30)  /* \x{7HHHHHHH} */

#define ONIG_SYN_OP2_ESC_CAPITAL_Q_QUOTE        (1<<0)   /* \Q...\E */
#define ONIG_SYN_OP2_QMARK_GROUP_EFFECT         (1<<1)   /* (?...) */
#define ONIG_SYN_OP2_OPTION_PERL                (1<<2)   /* (?imsx),(?-imsx) */
#define ONIG_SYN_OP2_OPTION_RUBY                (1<<3)   /* (?imx), (?-imx)  */
#define ONIG_SYN_OP2_PLUS_POSSESSIVE_REPEAT     (1<<4)   /* ?+,*+,++ */
#define ONIG_SYN_OP2_PLUS_POSSESSIVE_INTERVAL   (1<<5)   /* {n,m}+   */
#define ONIG_SYN_OP2_CCLASS_SET_OP              (1<<6)   /* [...&&..[..]..] */
#define ONIG_SYN_OP2_QMARK_LT_NAMED_GROUP       (1<<7)   /* (?<name>...) */
#define ONIG_SYN_OP2_ESC_K_NAMED_BACKREF        (1<<8)   /* \k<name> */
#define ONIG_SYN_OP2_ESC_G_SUBEXP_CALL          (1<<9)   /* \g<name>, \g<n> */
#define ONIG_SYN_OP2_ATMARK_CAPTURE_HISTORY     (1<<10)  /* (?@..),(?@<x>..) */
#define ONIG_SYN_OP2_ESC_CAPITAL_C_BAR_CONTROL  (1<<11)  /* \C-x */
#define ONIG_SYN_OP2_ESC_CAPITAL_M_BAR_META     (1<<12)  /* \M-x */
#define ONIG_SYN_OP2_ESC_V_VTAB                 (1<<13)  /* \v as VTAB */
#define ONIG_SYN_OP2_ESC_U_HEX4                 (1<<14)  /* \uHHHH */
#define ONIG_SYN_OP2_ESC_GNU_BUF_ANCHOR         (1<<15)  /* \`, \' */
#define ONIG_SYN_OP2_ESC_P_BRACE_CHAR_PROPERTY  (1<<16)  /* \p{...}, \P{...} */
#define ONIG_SYN_OP2_ESC_P_BRACE_CIRCUMFLEX_NOT (1<<17)  /* \p{^..}, \P{^..} */
#define ONIG_SYN_OP2_CHAR_PROPERTY_PREFIX_IS    (1<<18)  /* \p{IsXDigit} */
#define ONIG_SYN_OP2_ESC_H_XDIGIT               (1<<19)  /* \h, \H */

/* syntax (behavior) */
#define ONIG_SYN_CONTEXT_INDEP_ANCHORS           (1<<31) /* not implemented */
#define ONIG_SYN_CONTEXT_INDEP_REPEAT_OPS        (1<<0)  /* ?, *, +, {n,m} */
#define ONIG_SYN_CONTEXT_INVALID_REPEAT_OPS      (1<<1)  /* error or ignore */
#define ONIG_SYN_ALLOW_UNMATCHED_CLOSE_SUBEXP    (1<<2)  /* ...)... */
#define ONIG_SYN_ALLOW_INVALID_INTERVAL          (1<<3)  /* {??? */
#define ONIG_SYN_ALLOW_INTERVAL_LOW_ABBREV       (1<<4)  /* {,n} => {0,n} */
#define ONIG_SYN_STRICT_CHECK_BACKREF            (1<<5)  /* /(\1)/,/\1()/ ..*/
#define ONIG_SYN_DIFFERENT_LEN_ALT_LOOK_BEHIND   (1<<6)  /* (?<=a|bc) */
#define ONIG_SYN_CAPTURE_ONLY_NAMED_GROUP        (1<<7)  /* see doc/RE */
#define ONIG_SYN_ALLOW_MULTIPLEX_DEFINITION_NAME (1<<8)  /* (?<x>)(?<x>) */
#define ONIG_SYN_FIXED_INTERVAL_IS_GREEDY_ONLY   (1<<9)  /* a{n}?=(?:a{n})? */

/* syntax (behavior) in char class [...] */
#define ONIG_SYN_NOT_NEWLINE_IN_NEGATIVE_CC      (1<<20) /* [^...] */
#define ONIG_SYN_BACKSLASH_ESCAPE_IN_CC          (1<<21) /* [..\w..] etc.. */
#define ONIG_SYN_ALLOW_EMPTY_RANGE_IN_CC         (1<<22)
#define ONIG_SYN_ALLOW_DOUBLE_RANGE_OP_IN_CC     (1<<23) /* [0-9-a]=[0-9\-a] */
/* syntax (behavior) warning */
#define ONIG_SYN_WARN_CC_OP_NOT_ESCAPED          (1<<24) /* [,-,] */
#define ONIG_SYN_WARN_REDUNDANT_NESTED_REPEAT    (1<<25) /* (?:a*)+ */

/* meta character specifiers (onig_set_meta_char()) */
#define ONIG_META_CHAR_ESCAPE               0
#define ONIG_META_CHAR_ANYCHAR              1
#define ONIG_META_CHAR_ANYTIME              2
#define ONIG_META_CHAR_ZERO_OR_ONE_TIME     3
#define ONIG_META_CHAR_ONE_OR_MORE_TIME     4
#define ONIG_META_CHAR_ANYCHAR_ANYTIME      5

#define ONIG_INEFFECTIVE_META_CHAR          0

/* error codes */
#define ONIG_IS_PATTERN_ERROR(ecode)   ((ecode) <= -100 && (ecode) > -1000)
/* normal return */
#define ONIG_NORMAL                                            0
#define ONIG_MISMATCH                                         -1
#define ONIG_NO_SUPPORT_CONFIG                                -2

/* internal error */
#define ONIGERR_MEMORY                                         -5
#define ONIGERR_TYPE_BUG                                       -6
#define ONIGERR_PARSER_BUG                                    -11
#define ONIGERR_STACK_BUG                                     -12
#define ONIGERR_UNDEFINED_BYTECODE                            -13
#define ONIGERR_UNEXPECTED_BYTECODE                           -14
#define ONIGERR_MATCH_STACK_LIMIT_OVER                        -15
#define ONIGERR_DEFAULT_ENCODING_IS_NOT_SETTED                -21
#define ONIGERR_SPECIFIED_ENCODING_CANT_CONVERT_TO_WIDE_CHAR  -22
/* general error */
#define ONIGERR_INVALID_ARGUMENT                              -30 
/* syntax error */
#define ONIGERR_END_PATTERN_AT_LEFT_BRACE                    -100
#define ONIGERR_END_PATTERN_AT_LEFT_BRACKET                  -101
#define ONIGERR_EMPTY_CHAR_CLASS                             -102
#define ONIGERR_PREMATURE_END_OF_CHAR_CLASS                  -103
#define ONIGERR_END_PATTERN_AT_ESCAPE                        -104
#define ONIGERR_END_PATTERN_AT_META                          -105
#define ONIGERR_END_PATTERN_AT_CONTROL                       -106
#define ONIGERR_META_CODE_SYNTAX                             -108
#define ONIGERR_CONTROL_CODE_SYNTAX                          -109
#define ONIGERR_CHAR_CLASS_VALUE_AT_END_OF_RANGE             -110
#define ONIGERR_CHAR_CLASS_VALUE_AT_START_OF_RANGE           -111
#define ONIGERR_UNMATCHED_RANGE_SPECIFIER_IN_CHAR_CLASS      -112
#define ONIGERR_TARGET_OF_REPEAT_OPERATOR_NOT_SPECIFIED      -113
#define ONIGERR_TARGET_OF_REPEAT_OPERATOR_INVALID            -114
#define ONIGERR_NESTED_REPEAT_OPERATOR                       -115
#define ONIGERR_UNMATCHED_CLOSE_PARENTHESIS                  -116
#define ONIGERR_END_PATTERN_WITH_UNMATCHED_PARENTHESIS       -117
#define ONIGERR_END_PATTERN_IN_GROUP                         -118
#define ONIGERR_UNDEFINED_GROUP_OPTION                       -119
#define ONIGERR_INVALID_POSIX_BRACKET_TYPE                   -121
#define ONIGERR_INVALID_LOOK_BEHIND_PATTERN                  -122
#define ONIGERR_INVALID_REPEAT_RANGE_PATTERN                 -123
/* values error (syntax error) */
#define ONIGERR_TOO_BIG_NUMBER                               -200
#define ONIGERR_TOO_BIG_NUMBER_FOR_REPEAT_RANGE              -201
#define ONIGERR_UPPER_SMALLER_THAN_LOWER_IN_REPEAT_RANGE     -202
#define ONIGERR_EMPTY_RANGE_IN_CHAR_CLASS                    -203
#define ONIGERR_MISMATCH_CODE_LENGTH_IN_CLASS_RANGE          -204
#define ONIGERR_TOO_MANY_MULTI_BYTE_RANGES                   -205
#define ONIGERR_TOO_SHORT_MULTI_BYTE_STRING                  -206
#define ONIGERR_TOO_BIG_BACKREF_NUMBER                       -207
#define ONIGERR_INVALID_BACKREF                              -208
#define ONIGERR_NUMBERED_BACKREF_OR_CALL_NOT_ALLOWED         -209
#define ONIGERR_TOO_LONG_WIDE_CHAR_VALUE                     -212
#define ONIGERR_EMPTY_GROUP_NAME                             -214
#define ONIGERR_INVALID_GROUP_NAME                           -215
#define ONIGERR_INVALID_CHAR_IN_GROUP_NAME                   -216
#define ONIGERR_UNDEFINED_NAME_REFERENCE                     -217
#define ONIGERR_UNDEFINED_GROUP_REFERENCE                    -218
#define ONIGERR_MULTIPLEX_DEFINED_NAME                       -219
#define ONIGERR_MULTIPLEX_DEFINITION_NAME_CALL               -220
#define ONIGERR_NEVER_ENDING_RECURSION                       -221
#define ONIGERR_GROUP_NUMBER_OVER_FOR_CAPTURE_HISTORY        -222
#define ONIGERR_INVALID_CHAR_PROPERTY_NAME                   -223
#define ONIGERR_INVALID_WIDE_CHAR_VALUE                      -400
#define ONIGERR_TOO_BIG_WIDE_CHAR_VALUE                      -401
#define ONIGERR_NOT_SUPPORTED_ENCODING_COMBINATION           -402

/* errors related to thread */
#define ONIGERR_OVER_THREAD_PASS_LIMIT_COUNT                -1001


/* must be smaller than BIT_STATUS_BITS_NUM (unsigned int * 8) */
#define ONIG_MAX_CAPTURE_HISTORY_GROUP   31
#define ONIG_IS_CAPTURE_HISTORY_GROUP(r, i) \
  ((i) <= ONIG_MAX_CAPTURE_HISTORY_GROUP && (r)->list && (r)->list[i])

typedef struct OnigCaptureTreeNodeStruct {
  int group;   /* group number */
  int beg;
  int end;
  int allocated;
  int num_childs;
  struct OnigCaptureTreeNodeStruct** childs;
} OnigCaptureTreeNode;

/* match result region type */
struct re_registers {
  int  allocated;
  int  num_regs;
  int* beg;
  int* end;
  /* extended */
  OnigCaptureTreeNode* history_root;  /* capture history tree root */
};

/* capture tree traverse */
#define ONIG_TRAVERSE_CALLBACK_AT_FIRST   1
#define ONIG_TRAVERSE_CALLBACK_AT_LAST    2
#define ONIG_TRAVERSE_CALLBACK_AT_BOTH \
  ( ONIG_TRAVERSE_CALLBACK_AT_FIRST | ONIG_TRAVERSE_CALLBACK_AT_LAST )


#define ONIG_REGION_NOTPOS            -1

typedef struct re_registers   OnigRegion;

typedef struct {
  UChar* par;
  UChar* par_end;
} OnigErrorInfo;

typedef struct {
  int lower;
  int upper;
} OnigRepeatRange;

typedef void (*OnigWarnFunc) P_((char* s));
extern void onig_null_warn P_((char* s));
#define ONIG_NULL_WARN       onig_null_warn

#define ONIG_CHAR_TABLE_SIZE   256

/* regex_t state */
#define ONIG_STATE_NORMAL              0
#define ONIG_STATE_SEARCHING           1
#define ONIG_STATE_COMPILING          -1
#define ONIG_STATE_MODIFY             -2

#define ONIG_STATE(reg) \
  ((reg)->state > 0 ? ONIG_STATE_SEARCHING : (reg)->state)

typedef struct re_pattern_buffer {
  /* common members of BBuf(bytes-buffer) */
  unsigned char* p;         /* compiled pattern */
  unsigned int used;        /* used space for p */
  unsigned int alloc;       /* allocated space for p */

  int state;                     /* normal, searching, compiling */
  int num_mem;                   /* used memory(...) num counted from 1 */
  int num_repeat;                /* OP_REPEAT/OP_REPEAT_NG id-counter */
  int num_null_check;            /* OP_NULL_CHECK_START/END id counter */
  int num_call;                  /* number of subexp call */
  unsigned int capture_history;  /* (?@...) flag (1-31) */
  unsigned int bt_mem_start;     /* need backtrack flag */
  unsigned int bt_mem_end;       /* need backtrack flag */
  int stack_pop_level;
  int repeat_range_alloc;
  OnigRepeatRange* repeat_range;

  OnigEncoding  enc;
  OnigOptionType    options;
  OnigSyntaxType*   syntax;
  OnigAmbigType     ambig_flag;
  void*             name_table;

  /* optimization info (string search, char-map and anchors) */
  int            optimize;          /* optimize flag */
  int            threshold_len;     /* search str-length for apply optimize */
  int            anchor;            /* BEGIN_BUF, BEGIN_POS, (SEMI_)END_BUF */
  OnigDistance   anchor_dmin;       /* (SEMI_)END_BUF anchor distance */
  OnigDistance   anchor_dmax;       /* (SEMI_)END_BUF anchor distance */
  int            sub_anchor;        /* start-anchor for exact or map */
  unsigned char *exact;
  unsigned char *exact_end;
  unsigned char  map[ONIG_CHAR_TABLE_SIZE]; /* used as BM skip or char-map */
  int           *int_map;                   /* BM skip for exact_len > 255 */
  int           *int_map_backward;          /* BM skip for backward search */
  OnigDistance   dmin;                      /* min-distance of exact or map */
  OnigDistance   dmax;                      /* max-distance of exact or map */

  /* regex_t link chain */
  struct re_pattern_buffer* chain;  /* escape compile-conflict */
} regex_t;


typedef struct {
  int             num_of_elements;
  OnigEncoding    pattern_enc;
  OnigEncoding    target_enc;
  OnigSyntaxType* syntax;
  OnigOptionType  option;
  OnigAmbigType   ambig_flag;
} OnigCompileInfo;

/* Oniguruma Native API */
ONIG_EXTERN
int onig_init P_((void));
ONIG_EXTERN
int onig_error_code_to_str PV_((UChar* s, int err_code, ...));
ONIG_EXTERN
void onig_set_warn_func P_((OnigWarnFunc f));
ONIG_EXTERN
void onig_set_verb_warn_func P_((OnigWarnFunc f));
ONIG_EXTERN
int onig_new P_((regex_t**, UChar* pattern, UChar* pattern_end, OnigOptionType option, OnigEncoding enc, OnigSyntaxType* syntax, OnigErrorInfo* einfo));
ONIG_EXTERN
int onig_new_deluxe P_((regex_t** reg, UChar* pattern, UChar* pattern_end, OnigCompileInfo* ci, OnigErrorInfo* einfo));
ONIG_EXTERN
void onig_free P_((regex_t*));
ONIG_EXTERN
int onig_recompile P_((regex_t*, UChar* pattern, UChar* pattern_end, OnigOptionType option, OnigEncoding enc, OnigSyntaxType* syntax, OnigErrorInfo* einfo));
ONIG_EXTERN
int onig_recompile_deluxe P_((regex_t* reg, UChar* pattern, UChar* pattern_end, OnigCompileInfo* ci, OnigErrorInfo* einfo));
ONIG_EXTERN
int onig_search P_((regex_t*, UChar* str, UChar* end, UChar* start, UChar* range, OnigRegion* region, OnigOptionType option));
ONIG_EXTERN
int onig_match P_((regex_t*, UChar* str, UChar* end, UChar* at, OnigRegion* region, OnigOptionType option));
ONIG_EXTERN
OnigRegion* onig_region_new P_((void));
ONIG_EXTERN
void onig_region_free P_((OnigRegion* region, int free_self));
ONIG_EXTERN
void onig_region_copy P_((OnigRegion* to, OnigRegion* from));
ONIG_EXTERN
void onig_region_clear P_((OnigRegion* region));
ONIG_EXTERN
int onig_region_resize P_((OnigRegion* region, int n));
ONIG_EXTERN
int onig_name_to_group_numbers P_((regex_t* reg, UChar* name, UChar* name_end,
			            int** nums));
ONIG_EXTERN
int onig_name_to_backref_number P_((regex_t* reg, UChar* name, UChar* name_end, OnigRegion *region));
ONIG_EXTERN
int onig_foreach_name P_((regex_t* reg, int (*func)(UChar*,UChar*,int,int*,regex_t*,void*), void* arg));
ONIG_EXTERN
int onig_number_of_names P_((regex_t* reg));
ONIG_EXTERN
int onig_number_of_captures P_((regex_t* reg));
ONIG_EXTERN
int onig_number_of_capture_histories P_((regex_t* reg));
ONIG_EXTERN
OnigCaptureTreeNode* onig_get_capture_tree P_((OnigRegion* region));
ONIG_EXTERN
int onig_capture_tree_traverse P_((OnigRegion* region, int at, int(*callback_func)(int,int,int,int,int,void*), void* arg));
ONIG_EXTERN
OnigEncoding onig_get_encoding P_((regex_t* reg));
ONIG_EXTERN
OnigOptionType onig_get_options P_((regex_t* reg));
ONIG_EXTERN
OnigAmbigType onig_get_ambig_flag P_((regex_t* reg));
ONIG_EXTERN
OnigSyntaxType* onig_get_syntax P_((regex_t* reg));
ONIG_EXTERN
int onig_set_default_syntax P_((OnigSyntaxType* syntax));
ONIG_EXTERN
void onig_copy_syntax P_((OnigSyntaxType* to, OnigSyntaxType* from));
ONIG_EXTERN
unsigned int onig_get_syntax_op P_((OnigSyntaxType* syntax));
ONIG_EXTERN
unsigned int onig_get_syntax_op2 P_((OnigSyntaxType* syntax));
ONIG_EXTERN
unsigned int onig_get_syntax_behavior P_((OnigSyntaxType* syntax));
ONIG_EXTERN
OnigOptionType onig_get_syntax_options P_((OnigSyntaxType* syntax));
ONIG_EXTERN
void onig_set_syntax_op P_((OnigSyntaxType* syntax, unsigned int op));
ONIG_EXTERN
void onig_set_syntax_op2 P_((OnigSyntaxType* syntax, unsigned int op2));
ONIG_EXTERN
void onig_set_syntax_behavior P_((OnigSyntaxType* syntax, unsigned int behavior));
ONIG_EXTERN
void onig_set_syntax_options P_((OnigSyntaxType* syntax, OnigOptionType options));
ONIG_EXTERN
int onig_set_meta_char P_((OnigEncoding enc, unsigned int what, OnigCodePoint code));
ONIG_EXTERN
void onig_copy_encoding P_((OnigEncoding to, OnigEncoding from));
ONIG_EXTERN
unsigned int onig_get_match_stack_limit_size P_((void));
ONIG_EXTERN
int onig_set_match_stack_limit_size P_((unsigned int size));
ONIG_EXTERN
int onig_end P_((void));
ONIG_EXTERN
const char* onig_version P_((void));
ONIG_EXTERN
const char* onig_copyright P_((void));

#endif /* ONIGURUMA_H */
