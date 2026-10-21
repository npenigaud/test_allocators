// Wrapper C autour de oneapi::tbb::fixed_pool, appelé depuis Fortran (bind(C)).
// Non compilé ni testé : à valider sur votre machine.
//
// - une arène (buffer) unique, allouée une fois : posix_memalign, ou cudaHostAlloc
//   (mémoire épinglée) si PINNED=1 et compilation avec -DUSE_CUDA
// - tbbpool_alloc renvoie des adresses alignées sur "align" octets (puissance de 2),
//   le pointeur d'origine de fixed_pool étant rangé juste avant l'adresse rendue.

#define TBB_PREVIEW_MEMORY_POOL 1
#include "memory_pool.h"

#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <new>

#ifdef USE_CUDA
#include <cuda_runtime.h>
#endif

struct TbbPool {
  void*  buf    = nullptr;
  size_t nbytes = 0;
  size_t align  = 128;
  int    pinned = 0;
  oneapi::tbb::fixed_pool* pool = nullptr;
};

static void release_buffer(TbbPool* h) {
  if (!h->buf) return;
#ifdef USE_CUDA
  if (h->pinned) { cudaFreeHost(h->buf); h->buf = nullptr; return; }
#endif
  free(h->buf);
  h->buf = nullptr;
}

extern "C" {

void* tbbpool_create(size_t nbytes, size_t align, int pinned) {
  TbbPool* h = new (std::nothrow) TbbPool();
  if (!h) return nullptr;
  h->nbytes = nbytes;
  h->align  = align;
  h->pinned = pinned;

  if (pinned) {
#ifdef USE_CUDA
    if (cudaHostAlloc(&h->buf, nbytes,
                      cudaHostAllocMapped | cudaHostAllocPortable) != cudaSuccess) {
      fprintf(stderr, "tbbpool: cudaHostAlloc a échoué\n");
      delete h;
      return nullptr;
    }
#else
    fprintf(stderr, "tbbpool: mémoire épinglée demandée, mais compilé sans -DUSE_CUDA\n");
    delete h;
    return nullptr;
#endif
  } else if (posix_memalign(&h->buf, 4096, nbytes) != 0) {
    fprintf(stderr, "tbbpool: posix_memalign a échoué\n");
    delete h;
    return nullptr;
  }

  try {
    h->pool = new oneapi::tbb::fixed_pool(h->buf, nbytes);
  } catch (...) {
    fprintf(stderr, "tbbpool: construction de fixed_pool impossible (arène trop petite ?)\n");
    release_buffer(h);
    delete h;
    return nullptr;
  }
  return h;
}

void* tbbpool_buffer(void* hp) { return static_cast<TbbPool*>(hp)->buf; }

void* tbbpool_alloc(void* hp, size_t n) {
  TbbPool* h = static_cast<TbbPool*>(hp);
  char* raw = static_cast<char*>(h->pool->malloc(n + h->align + sizeof(void*)));
  if (!raw) return nullptr;
  uintptr_t p = (reinterpret_cast<uintptr_t>(raw) + sizeof(void*) + h->align - 1)
                & ~static_cast<uintptr_t>(h->align - 1);
  reinterpret_cast<void**>(p)[-1] = raw;
  return reinterpret_cast<void*>(p);
}

void tbbpool_free(void* hp, void* p) {
  if (!p) return;
  static_cast<TbbPool*>(hp)->pool->free(reinterpret_cast<void**>(p)[-1]);
}

// Remet le pool à zéro : tous les pointeurs obtenus deviennent invalides.
void tbbpool_recycle(void* hp) { static_cast<TbbPool*>(hp)->pool->recycle(); }

// Plus gros bloc que fixed_pool accepte d'allouer (recherche par dichotomie), en octets.
// hi : borne haute (par exemple la taille de l'arène). À appeler sur un pool neuf, dans un
// processus dédié aux mesures : le pool a été manipulé, ne l'utilisez plus ensuite.
// Taille brute demandée à fixed_pool, sans le supplément d'alignement de tbbpool_alloc
// (align + sizeof(void*) octets de moins pour un vrai tableau).
size_t tbbpool_probe(void* hp, size_t hi) {
  TbbPool* h = static_cast<TbbPool*>(hp);
  size_t lo = 0;
  while (hi - lo > 4096) {
    size_t mid = lo + (hi - lo) / 2;
    void* p = h->pool->malloc(mid);
    if (p) { h->pool->free(p); lo = mid; } else hi = mid;
  }
  return lo;
}

void tbbpool_destroy(void* hp) {
  TbbPool* h = static_cast<TbbPool*>(hp);
  if (!h) return;
  delete h->pool;      // le pool d'abord, puis le buffer qu'il gérait
  release_buffer(h);
  delete h;
}

} // extern "C"
