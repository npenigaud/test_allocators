#include <stdlib.h>
#include <stddef.h>

void * alloc_aligned(size_t alignment, size_t size_bytes)
{
  void * buffer;
  posix_memalign(&buffer,alignment, size_bytes);
//  return aligned_alloc(alignment, size_bytes); can be aligned on less than size(void*)
  return buffer; 
}

void free_aligned(void ** buffer)
{
  free(*buffer);
}
