! Mesure du surcoût de tbb::fixed_pool : plus gros bloc allouable dans un pool neuf,
! pour plusieurs tailles d'arène. Non compilé ni testé : à valider sur votre machine.
PROGRAM ESSAI_PROBE

USE FIAT_TBBPOOL_MOD, ONLY : FIAT_TBBPOOL
USE ISO_C_BINDING,    ONLY : C_SIZE_T

IMPLICIT NONE

INTEGER(KIND=C_SIZE_T), PARAMETER :: MIB = 1024_C_SIZE_T**2
INTEGER, PARAMETER :: ITAILLES(18) = [256, 512, 1024, 1142, 1152, 1634, 1644, 1654, 1664, 1674, 1684, 1694, 1714, 1704, 1724, 1792 , 1920, 2048]   ! tailles d'arène en Mio

TYPE(FIAT_TBBPOOL) :: POOL
INTEGER(KIND=C_SIZE_T) :: ISIZE, IMAX
INTEGER :: I

DO I = 1, SIZE (ITAILLES)

  ISIZE = ITAILLES(I) * MIB

  ! pool neuf à chaque taille : le pool est manipulé par la mesure, on ne le réutilise pas
  CALL POOL%INIT (ISIZE)

  IMAX = POOL%PROBE (ISIZE)

  WRITE (*, '(A,I6,A,I12,A,I12,A,F7.3,A)') &
    & "arene (Mio):", ITAILLES(I), "  plus gros bloc (octets):", IMAX, &
    & "  perte (octets):", ISIZE-IMAX, "  soit ", &
    & 100._8 * REAL (ISIZE-IMAX, 8) / REAL (ISIZE, 8), " %"

  CALL POOL%FINAL

ENDDO

END PROGRAM ESSAI_PROBE
