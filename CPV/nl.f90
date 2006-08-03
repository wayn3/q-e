!
! Copyright (C) 2002-2005 FPMD-CPV groups
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!

#include "f_defs.h"

!

   FUNCTION nlrh_x( c0, tforce, fion, bec, becdr, eigr )

      !  this routine computes:
      !  Kleinman-Bylander pseudopotential terms (see nlsm1)
      !  enl: nonlocal potential contribution to total energy (see ene_nl)
      !  nonlocal potential contribution to forces on ions, see nlsm2
      !
      ! ... include modules

      USE kinds,                   ONLY: DP
      USE read_pseudo_module_fpmd, ONLY: nspnl
      USE electrons_base,          ONLY: iupdwn, nupdwn, nspin
      USE gvecw,                   ONLY: ngw
      USE uspp,                    ONLY: becsum, nkb

      IMPLICIT NONE

      REAL(DP) :: nlrh_x

      ! ... declare subroutine arguments

      COMPLEX(DP)                 :: eigr(:,:)     ! exp(i G dot r)
      COMPLEX(DP), INTENT(INOUT)  :: c0(:,:)       ! wave functions
      LOGICAL,     INTENT(IN)     :: tforce        ! if .TRUE. compute forces on ions
      REAL(DP),    INTENT(INOUT)  :: fion(:,:)     ! atomic forces
      REAL(DP)                    :: bec(:,:)
      REAL(DP)                    :: becdr(:,:,:)

      REAL(DP)    :: ennl
      EXTERNAL    :: ennl

      ! ... declare other variables
      !
      INTEGER     :: iss, i, j
      REAL(DP)    :: etmp
      REAL(DP), ALLOCATABLE :: btmp( :, :, : )

      ! ... end of declarations
      !

      DO iss = 1, nspin
         !
         CALL nlsm1 ( nupdwn( iss ), 1, nspnl, eigr(1,1),    &
                      c0( 1, iupdwn( iss ) ), bec(1, iupdwn( iss ) ) )
         !
         IF( tforce ) THEN
            !
            ALLOCATE( btmp( nkb, nupdwn( iss ), 3 ) ) 
            !
            CALL nlsm2( ngw, nkb, nupdwn( iss ), eigr(1,1), &
                        c0( 1, iupdwn( iss ) ), btmp( 1, 1, 1 ), .false. )
            !
            DO i = 1, 3
               DO j = iupdwn( iss ), iupdwn( iss ) + nupdwn( iss ) - 1
                  becdr( :, j , i ) = btmp( :, j - iupdwn( iss ) + 1, i ) 
               END DO
            END DO
            !
            DEALLOCATE( btmp )
            !
         END IF
         !
      END DO
      
      nlrh_x = ennl( becsum, bec )

      IF( tforce ) THEN
         !
         CALL force_nl( fion, bec, becdr )
         !
      END IF
      !
      RETURN
   END FUNCTION nlrh_x

