#ifdef _WIN32
#include <windows.h>
#else /* POSIX */
#include <dirent.h>
#include <sys/types.h> /* for stat */
#include <sys/stat.h> /* for stat */
#include <errno.h>
#endif

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include <stdio.h>

#ifdef _WIN32
#include <string.h>
static char lbuffer[510];

static char *local_append (const char *src, const char *data) {

   sprintf ((char *)lbuffer, "%s%s", src, data);
   return (char *)lbuffer;
}
#endif

static int lmk_system (lua_State *L) {

#if defined (_WIN32)
   char str[] = "win32";
#elif defined (__linux)
   char str[] = "linux";
#elif defined (__APPLE__) || defined (MACOSX)
   char str[] = "macos";
#elif defined (__sgi)
   char str[] = "irix";
#else
   char str[] = "unknown";
#endif

   lua_pushstring (L, str);

   return 1;
}


static int lmk_pwd (lua_State *L) {

   int result = 1;

#ifdef _WIN32
   DWORD size = GetCurrentDirectory (0, 0);
   char *ptr = (char *)malloc ((size + 1) * sizeof (char));
   if (ptr && GetCurrentDirectory (size + 1, ptr)) { lua_pushstring (L, ptr); }
#else /* POSIX */
   char path[255+2];
   if (getcwd (path, 255)) { lua_pushstring (L, path); }
#endif
   else {

      lua_pushnil (L);
      lua_pushstring (L, "failed getting cwd");
      result = 2;
   }
#ifdef _WIN32
   if (ptr) { free (ptr); ptr = 0; }
#endif

   return result;
}


static int lmk_cd (lua_State *L) {

   int result = 1;
   const char *path = luaL_checkstring (L, 1);

#ifdef _WIN32
   if (SetCurrentDirectory (path)) { lua_pushboolean (L, 1); }
#else /* POSIX */
   if (!chdir (path)) { lua_pushboolean (L, 1); }
#endif
   else  {

      lua_pushnil (L);
      lua_pushfstring (L, "Unable to change working directory to '%s'", path);
      result = 2;
   }

   return result;
}


static int lmk_files (lua_State *L) {

   int result = 1;
   const char *path = luaL_checkstring (L, 1);

#ifdef _WIN32
   WIN32_FIND_DATA data;
   HANDLE h = FindFirstFile (local_append (path, "/*"), &data);
   int count = 1;
   lua_newtable (L);

   if (h != INVALID_HANDLE_VALUE) {

      do {

         if (!(data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)) {

            lua_pushstring (L, data.cFileName);
            lua_rawseti (L, -2, count);
            count++;
         }
      } while (FindNextFile (h, &data));

      FindClose (h);
   }
#else /* POSIX */
   DIR *d = opendir (path);

   if (d) {

      struct dirent *c = readdir (d);
      int count = 1;

      lua_newtable (L);

      while (c) {

         if (c->d_type != DT_DIR) {

            lua_pushstring (L, c->d_name);
            lua_rawseti (L, -2, count);
            count++;
         }

         c = readdir (d);
      }

      closedir (d); d = 0;
   }
#endif
   else {

      lua_pushnil (L);
      lua_pushfstring (L, "Unable to open directory: %s", path);
      result = 2;
   }

   return result;
}


static int lmk_directories (lua_State *L) {

   int result = 1;
   const char *path = luaL_checkstring (L, 1);

#ifdef _WIN32
   WIN32_FIND_DATA data;
   HANDLE h = FindFirstFile (local_append (path, "/*"), &data);
   int error = 0;
   int count = 1;
   lua_newtable (L);

   if (h != INVALID_HANDLE_VALUE) {

      do {

         if (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {

            int store = 1;

            if (data.cFileName[0] == '.') {

               if ((data.cFileName[1] == '\0') ||
                     ((data.cFileName[1] == '.') && (data.cFileName[2] == '\0'))) {

                  store = 0;
               }
            }

            if (store) {

               lua_pushstring (L, data.cFileName);
               lua_rawseti (L, -2, count);
               count++;
            }
         }
      } while (FindNextFile (h, &data));

      FindClose (h);
   }
#else /* POSIX */
   DIR *d = opendir (path);

   if (d) {

      struct dirent *c = readdir (d);
      int count = 1;

      lua_newtable (L);

      while (c) {

         if (c->d_type == DT_DIR) {

            int store = 1;

            if (c->d_name[0] == '.') {

               if ((c->d_name[1] == '\0') ||
                  ((c->d_name[1] == '.') && (c->d_name[2] == '\0'))) {

                  store = 0;
               }
            }

            if (store) {

               lua_pushstring (L, c->d_name);
               lua_rawseti (L, -2, count);
               count++;
            }
         }

         c = readdir (d);
      }

      closedir (d); d = 0;
   }
#endif
   else {

      lua_pushnil (L);
      lua_pushfstring (L, "Unable to open directory: %s", path);
      result = 2;
   }

   return result;
}


static int lmk_rm (lua_State *L) {

   int result = 1;
   const char *path = luaL_checkstring (L, 1);

#ifdef _WIN32
   WIN32_FILE_ATTRIBUTE_DATA data;
   memset ((void *) &data, '\0', sizeof (WIN32_FILE_ATTRIBUTE_DATA));

   if (GetFileAttributesEx (path, GetFileExInfoStandard, &data)) {

      BOOL result = FALSE;
      DWORD att = data.dwFileAttributes & (~FILE_ATTRIBUTE_READONLY);
      SetFileAttributes (path, att);

      if (att & FILE_ATTRIBUTE_DIRECTORY) { result = RemoveDirectory (path); }
      else { result = DeleteFile (path); }

      if (result) { lua_pushboolean (L, 1); }
      else {

         lua_pushnil (L);

         lua_pushfstring (
            L,
            "Unable to remove: '%s'",
            path);

         result = 2;
      }
   }
#else /* POSIX */
   struct stat s;

   if (!stat (path, &s)) {

      /* make sure we can remove the item */
      if (!s.st_mode & S_IWUSR) {

         chmod (path, s.st_mode | S_IWUSR);
      }

/*
      if (S_ISDIR (s.st_mode)) {

         rmdir (path);
      }
*/
      if (!remove (path)) { lua_pushboolean (L, 1); }
      else {

         lua_pushnil (L);

         lua_pushfstring (
            L,
            "Unable to remove: '%s' because: %s",
            path,
            strerror (errno));

         result = 2;
      }
   }
#endif
   else {

      lua_pushnil (L);
      lua_pushfstring (L, "Unable to find item: %s", path);
      result = 2;
   }

   return result;
}


static int lmk_mkdir (lua_State *L) {

   int result = 1;
   const char *path = luaL_checkstring (L, 1);

#ifdef _WIN32
   if (CreateDirectory (path, 0)) { lua_pushboolean (L, 1); }
#else /* POSIX */
   if (!mkdir (path, S_IRUSR | S_IWUSR | S_IXUSR)) { lua_pushboolean (L, 1); }
#endif
   else {

      lua_pushnil (L);
      lua_pushfstring (L, "Unable to create directory: %s", path);
      result = 2;
   }

   return result;
}


static int lmk_file_newer (lua_State *L) {

   int result = 1;
   const char *file1 = luaL_checkstring (L, 1);
   const char *file2 = luaL_checkstring (L, 2);

#ifdef _WIN32
   WIN32_FILE_ATTRIBUTE_DATA data1;
   WIN32_FILE_ATTRIBUTE_DATA data2;
   memset ((void *) &data1, '\0', sizeof (WIN32_FILE_ATTRIBUTE_DATA));
   memset ((void *) &data2, '\0', sizeof (WIN32_FILE_ATTRIBUTE_DATA));

   if (GetFileAttributesEx (file1, GetFileExInfoStandard, &data1) &&
         GetFileAttributesEx (file2, GetFileExInfoStandard, &data2)) {

      if (CompareFileTime (&(data1.ftLastWriteTime), &(data2.ftLastWriteTime)) > 0) {

         lua_pushboolean (L, 1);
      }
      else { lua_pushboolean (L, 0); }
   }
#else /* POSIX */
   struct stat s1, s2;

   if (!stat (file1, &s1) && !stat (file2, &s2)) {

      if (s1.st_mtime > s2.st_mtime) { lua_pushboolean (L, 1); }
      else { lua_pushboolean (L, 0); }
   }
#endif
   else {

      lua_pushnil (L);
      lua_pushfstring (
         L,
         "Unable to compare dates of files: %s and %s",
         file1,
         file2);
      result = 2;
   }

   return result;
}


static int lmk_is_valid (lua_State *L) {

   int result = 1;
   const char *path = luaL_checkstring (L, 1);

#ifdef _WIN32
   WIN32_FILE_ATTRIBUTE_DATA data;
   memset ((void *) &data, '\0', sizeof (WIN32_FILE_ATTRIBUTE_DATA));

   if (GetFileAttributesEx (path, GetFileExInfoStandard, &data)) { lua_pushboolean (L, 1); }
#else /* POSIX */
   struct stat s;

   if (!stat (path, &s)) { lua_pushboolean (L, 1); }
#endif
   else {

      lua_pushnil (L);
      lua_pushfstring (L, "Path not valid: %s", path);
      result = 2;
   }

   return result;
}


static int lmk_is_dir (lua_State *L) {

   int result = 1;
   const char *path = luaL_checkstring (L, 1);

#ifdef _WIN32
   WIN32_FILE_ATTRIBUTE_DATA data;
   memset ((void *) &data, '\0', sizeof (WIN32_FILE_ATTRIBUTE_DATA));

   if (GetFileAttributesEx (path, GetFileExInfoStandard, &data)) {

      if (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) { lua_pushboolean (L, 1); }
      else { lua_pushboolean (L, 0); }
   }
#else /* POSIX */
   struct stat s;

   if (!stat (path, &s)) {

      if (S_ISDIR (s.st_mode)) { lua_pushboolean (L, 1); }
      else { lua_pushboolean (L, 0); }
   }
#endif
   else {

      lua_pushnil (L);
      lua_pushfstring (L, "Path not valid: %s", path);
      result = 2;
   }

   return result;
}


static const struct luaL_reg lmkbaselib[] = {
   {"system", lmk_system},
   {"pwd", lmk_pwd},
   {"cd", lmk_cd},
   {"files", lmk_files},
   {"directories", lmk_directories},
   {"rm", lmk_rm},
   {"mkdir", lmk_mkdir},
   {"file_newer", lmk_file_newer},
   {"is_valid", lmk_is_valid},
   {"is_dir", lmk_is_dir},
   {NULL, NULL},
};

#ifdef _WIN32
__declspec (dllexport)
#endif
int luaopen_lmkbase (lua_State *L) {

   luaL_openlib (L, "lmkbase", lmkbaselib, 0);
 
   return 1;
}

