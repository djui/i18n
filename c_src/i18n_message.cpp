/* vim: set filetype=cpp shiftwidth=4 tabstop=4 expandtab tw=80: */

/**
 *  =====================================================================
 *    Copyright 2011 Uvarov Michael 
 * 
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 * 
 *        http://www.apache.org/licenses/LICENSE-2.0
 * 
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 * 
 *  $Id$
 * 
 *  @copyright 2010-2011 Michael Uvarov
 *  @author Michael Uvarov <freeakk@gmail.com>
 *  =====================================================================
 */


#include "i18n_nif.h"
#include "i18n_message.h"

#if I18N_MESSAGE


U_NAMESPACE_BEGIN
/**
 * This class isolates our access to private internal methods of
 * MessageFormat.  It is never instantiated; it exists only for C++
 * access management.
 */
class MessageFormatAdapter {
public:
    static const Formattable::Type* getArgTypeList(const MessageFormat& m,
                                                   int32_t& count);
};
const Formattable::Type*
MessageFormatAdapter::getArgTypeList(const MessageFormat& m,
                                     int32_t& count) {
    return m.getArgTypeList(count);
}
U_NAMESPACE_END

U_NAMESPACE_USE





static ErlNifResourceType* message_type = 0;


/* Called from erl_nif. */
static void message_dtor(ErlNifEnv* /*env*/, void* obj) 
{
    /* Free memory */
    cloner_destroy((cloner*) obj); 
}



/* Called from cloner for each thread. */
static void message_close(char* obj) 
{ 
    if (obj != NULL)
        umsg_close((UMessageFormat*) obj);
}

static char* message_clone(char* obj) 
{
    UErrorCode status = U_ZERO_ERROR;

    obj = (char*) umsg_clone(
        (UMessageFormat*) obj,
        &status 
    );
    if(U_FAILURE(status)) { 
        return NULL;
    } 
    return obj;
}

static int message_open(UMessageFormat * obj, cloner* c)
{
    return cloner_open((char *) obj, c, &message_clone, &message_close);
} 








/**
 * NIFs
 */

/* Get a message format 
 * i18n:to(i18n_message:format(i18n_message:open(i18n:from("{0,date}")),
 * [{i18n:from("0"), i18n_nif:date_now()}])).  
 * <<"2011 9 28">> */

ERL_NIF_TERM open_format(ErlNifEnv* env, int argc, 
    const ERL_NIF_TERM argv[])
{
    ERL_NIF_TERM out;
    ErlNifBinary in;
    char locale[LOCALE_LEN];
    UErrorCode status = U_ZERO_ERROR;
    UParseError pe;
    UMessageFormat* msg;
    cloner* res;

    if (argc != 2)
        return enif_make_badarg(env);

    if (!(enif_get_atom(env, argv[0], (char*) locale, 
                LOCALE_LEN, ERL_NIF_LATIN1)
          && enif_inspect_binary(env, argv[1], &in))) {
        return enif_make_badarg(env);
    }

    /* get a message format */
    msg = umsg_open((UChar *) in.data, 
            TO_ULEN(in.size),
            (char *) locale, 
            &pe, 
            &status);
    if (U_FAILURE(status)) {
        return parse_error(env, status, &pe);
    }


    res = (cloner*) enif_alloc_resource(message_type, sizeof(cloner));
    if (message_open(msg, res)) {
        enif_release_resource(res);
        return enif_make_badarg(env);
    }
    out = enif_make_resource(env, res);
    enif_release_resource(res);
    /* resource now only owned by "Erlang" */
    return out;
}
/* Non-localized realization */
inline void append_uint(unsigned int n, UnicodeString& s)
{
    int tenth;

    do {
        tenth = n / 10;
        s.append((UChar)(n - 10 * tenth + '0'));
        n = tenth;
    } while (n != 0);
}

inline static void append_atom(char * atom, UnicodeString& s)
{
    while (*atom) {
        s.append((UChar) *atom);
        atom++;
    } 
}

ERL_NIF_TERM format(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    ErlNifBinary in, name;
    ERL_NIF_TERM out, list, argt;
    int32_t len, mcount; 
    cloner* ptr;
    unsigned int count, i;
    UErrorCode status = U_ZERO_ERROR;
    UnicodeString appendTo;
    const MessageFormat* fmt;
    const Formattable::Type* types;

    ERL_NIF_TERM* tuple;
    double tDouble;
    int tInt;
    ErlNifSInt64 tInt64;

    if ((argc != 2) && (argc != 3))
        return enif_make_badarg(env);

    if(!(enif_get_list_length(env, argv[1], &count)
      && enif_get_resource(env, argv[0], message_type, (void**) &ptr))) {
        return enif_make_badarg(env);
    }

    fmt = (const MessageFormat*) cloner_get(ptr);
    CHECK_RES(env, fmt);


    if (argc == 3) {
        if (enif_inspect_binary(env, argv[2], &in)) {
            appendTo.append((UChar*) in.data, 
                TO_ULEN(in.size));
        } else {
            /* Third elem is not a string */
            return enif_make_badarg(env);
        }
    }

    /* Allocate at least one element.  Allocating an array of length
     * zero causes problems on some platforms (e.g. Win32).
     */
    Formattable* args = new Formattable[count ? count : 1];
    UnicodeString* names = new UnicodeString[count ? count : 1];

    i = 0;
    list = argv[1];

    /* TODO: dirty, but stable
     * If we use c API we cannot check args.
     * If we use c++ API we cannot get requered type.
     * So we will use c++ API for c implementation (private API). */
    types = MessageFormatAdapter::getArgTypeList(*fmt, mcount);

    if (mcount < (int32_t) count) 
        return enif_make_badarg(env); /* too few elements in the list */

    while (enif_get_list_cell(env, list, &out, &list)) {

        if (enif_get_tuple(env, out, &len, (const ERL_NIF_TERM**) &tuple)
            && (len == 2)) { 
            /* [..., {Id, Arg}, ...] */
            /* Inspect first element of the tuple (extract the name) */

            if (enif_inspect_binary(env, tuple[0], &name)) {
                /* typeof(Id) == unicode_string */
                names[i].append((UChar*) name.data, 
                    (int32_t) TO_ULEN(name.size));
            } else 

            if (enif_get_int(env, tuple[0], &tInt)) {
                /* typeof(Id) == integer */
                append_uint(tInt, names[i]);
            } else 

            if (enif_is_atom(env, tuple[0])) {
                /* typeof(Id) == atom */
                char atom[ATOM_LEN];
                if (!enif_get_atom(env, tuple[0], (char*) atom, ATOM_LEN,
                    ERL_NIF_LATIN1))
                    goto bad_elem;
                
                append_atom((char *) atom, names[i]);
                    
            } else 
                goto bad_elem;

                
            argt = tuple[1];
        } else {
            /* [..., Arg, ...] */
            argt = out;
            append_uint((unsigned int) i, names[i]);
        }


        /* out is a head
           len is arity
           reuse name variable as an argument */
        switch (types[i]) {
            
            case Formattable::kDate:
 
                if (!enif_get_double(env, argt, &tDouble)) 
                    goto bad_elem;

                args[i].setDate((UDate) tDouble);
                break;
            
            case Formattable::kDouble:
 
                if (!enif_get_double(env, argt, &tDouble)) 
                    goto bad_elem;

                args[i].setDouble(tDouble);
                break;
            
            case Formattable::kLong:
 
                if (!enif_get_int(env, argt, &tInt))
                    goto bad_elem;

                args[i].setLong((int32_t) tInt);
                break;
 
            case Formattable::kInt64:

                if (!enif_get_int64(env, argt, &tInt64)) 
                    goto bad_elem;

                args[i].setInt64((int64_t) tInt64);
                break;
                
            case Formattable::kString:

                if (!enif_inspect_binary(env, argt, &name)) 
                    goto bad_elem;

                args[i].setString(
                    * new UnicodeString(
                        (const UChar*) name.data, 
                        (int32_t) TO_ULEN(name.size)));
                break;
 
           default:
                goto bad_elem;
        }
        
        i++;
    }
    
    fmt->format(
        (const UnicodeString *) names,
        (const Formattable *) args,
        (int32_t) count,
        appendTo,
        status      
    );
    delete[] args;
    delete[] names;

    CHECK(env, status);

    return string_to_term(env, appendTo);

    bad_elem:
        /* Memory deallocation */
        delete[] args;
        delete[] names;
        return list_element_error(env, argv[1], i);
}







int i18n_message_load(ErlNifEnv *env, void ** /*priv_data*/, 
    ERL_NIF_TERM /*load_info*/)
{
    ErlNifResourceFlags flags = (ErlNifResourceFlags)(ERL_NIF_RT_CREATE |
        ERL_NIF_RT_TAKEOVER);

    message_type = enif_open_resource_type(env, NULL, "message_type",
        message_dtor, flags, NULL); 
    if (message_type == NULL) return 5;
    return 0;
}
#endif
