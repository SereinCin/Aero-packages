/* aero-sqlite C shim: wraps sqlite3 to expose Aero-friendly signatures.
 * Aero FFI cannot return `str` and has no i8 pointer type; this shim keeps all
 * sqlite3 pointer/text handling in C and hands Aero i64 handles + text buffers.
 */
#include <sqlite3.h>
#include <string.h>

/* Execute a SELECT; writes "a,b;c,d" (rows ';', cols ',') into outbuf.
 * Returns bytes written, or -1 on error. */
long long ash_query(long long db, const char *sql, char *outbuf, long long outcap) {
    sqlite3_stmt *stmt = 0;
    int rc = sqlite3_prepare_v2((sqlite3 *)db, sql, -1, &stmt, 0);
    if (rc != 0) {
        return -1;
    }
    long long pos = 0;
    int first = 1;
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        int cc = sqlite3_column_count(stmt);
        if (!first) {
            if (pos + 1 < outcap) {
                outbuf[pos++] = ';';
            }
        }
        first = 0;
        for (int i = 0; i < cc; i++) {
            if (i > 0) {
                if (pos + 1 < outcap) {
                    outbuf[pos++] = ',';
                }
            }
            const unsigned char *t = sqlite3_column_text(stmt, i);
            if (t) {
                long long n = (long long)strlen((const char *)t);
                if (pos + n < outcap) {
                    memcpy(outbuf + pos, t, n);
                    pos += n;
                }
            }
        }
    }
    sqlite3_finalize(stmt);
    if (pos + 1 <= outcap) {
        outbuf[pos] = '\0';
    }
    return pos;
}

/* Execute DDL/DML; returns 0 on success, -1 on error (message to errbuf). */
long long ash_exec(long long db, const char *sql, char *errbuf, long long errcap) {
    char *err = 0;
    int rc = sqlite3_exec((sqlite3 *)db, sql, 0, 0, &err);
    if (rc != 0) {
        if (err && errbuf && errcap > 0) {
            strncpy(errbuf, err, (size_t)(errcap - 1));
            errbuf[errcap - 1] = '\0';
        }
        sqlite3_free(err);
        return -1;
    }
    return 0;
}
