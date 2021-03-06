program GETPAR
    USE DDPRECISION,ONLY: WP

    ! modules used to transfer allocatable variables:

    USE READNF_ECOM,ONLY: CXADIA,CXEINC,CXEPS,CXESCA,CXPOL,ICOMP
    USE READNF_BCOM,ONLY: CXBINC,CXBSCA
    IMPLICIT NONE

    ! arguments

    CHARACTER*60 :: CFLENAME
    CHARACTER*26 :: CSTAMP
    !!
    CHARACTER*20 :: FLAG,XOFFSET,XNSLICE

    INTEGER :: IDVOUT,NAT0,NCOMP,NRFLDB,NX,NY,NZ,VERSNUM
    !!
    INTEGER :: NARGIN

    !!
    REAL(WP) :: OFFSET
    INTEGER :: NSLICE
	CHARACTER*200 :: SLICESETTING



    REAL(WP) ::                                             &
     AEFF,DPHYS,NAMBIENT,WAVE,XMAX,XMIN,YMAX,YMIN,ZMAX,ZMIN

    REAL(WP) ::  &
     AK_TF(3), &
     X0(3)     !

    COMPLEX(WP) :: &
     CXB0_TF(3), &
     CXE0_TF(3)  !

    ! local variables

    LOGICAL INIT

    INTEGER IC,ILINE,IOBIN,DDP,IX1,IY1,IZ1,J,J1,JX,JY,JZ, &
     K,NAT3,RWORD,NRWORD,NRWORD_NF,NXY,NXYZ         !

    REAL(WP) ::                               &
     EINC2,PHI0,PHIYZ,PHIZ,PI,SUMERR2,TINY, &
     W1,W2,W3,W4,W5,W6,W7,W8,WX,WY,WZ,      &
     XA,XB,YA,YB,ZA,ZB,ZETA                 !

    COMPLEX(WP) :: CXERR,CXFAC,CXI,CXPHAS

    DATA INIT/.FALSE./,CXI/(0.,1._WP)/
    SAVE CXI,INIT,NRWORD,PI
    !=================================================================
    ! determine word length
    IF(INIT)THEN

        ! elements of READNF_ECOM:

        DEALLOCATE(CXADIA)
        DEALLOCATE(CXEINC)
        DEALLOCATE(CXEPS)
        DEALLOCATE(CXESCA)
        DEALLOCATE(CXPOL)
        DEALLOCATE(ICOMP)

        ! elements of READNF_BCOM

        IF(NRFLDB==1)THEN
            DEALLOCATE(CXBINC)
            DEALLOCATE(CXBSCA)
        ENDIF
    ENDIF

    IF(.NOT.INIT)THEN
        IF(WP==KIND(0.E0))THEN
            NRWORD=4
        ELSEIF(WP==KIND(0.D0))THEN
            NRWORD=8
        ELSE
            WRITE(0,*)'Fatal error determining word length in READNF'
            STOP
        ENDIF
        WRITE(IDVOUT,FMT='(A,I2)')'>READNF word length=',NRWORD
        PI=4._WP*ATAN(1._WP)
        INIT=.TRUE.
    ENDIF

!              >>>>> Important Note! <<<<<
! The structure of the READ statements below *must* conform to the
! structure of the corresponding WRITE statements in nearfield.f90
! Any changes must be made in both modules.

    IOBIN=17
    CFLENAME='w000r000k000.E1'
    OPEN(UNIT=IOBIN,FILE=CFLENAME,ACCESS='STREAM')
!*** diagnostic
!      write(0,*)'readnf ckpt 3'
!***
    READ(IOBIN)CSTAMP,VERSNUM
    WRITE(IDVOUT,FMT='(2A)')'>READNF data from ',CSTAMP
!*** diagnostic
!      write(0,*)'readnf ckpt 4, cstamp=',cstamp
!      write(0,*)'              versnum=',versnum
!***
    IF(VERSNUM.EQ.730)THEN
!*** diagnostic
!         write(0,*)'readnf ckpt 5, about to read file'
!***
        READ(IOBIN)NRWORD_NF,NRFLDB,NXYZ,NAT0,NAT3,NCOMP,NX,NY,NZ,X0,AEFF, &
                NAMBIENT,WAVE,AK_TF,CXE0_TF,CXB0_TF
!*** diagnostic
!         write(0,*)'readnf ckpt 6, nrword_nf=',nrword_nf
!***
    ELSE
        WRITE(0,FMT='(3A,I4)')'file=',CFLENAME,                 &
                            ' was written by version=',VERSNUM
        WRITE(0,FMT='(2A)')'file is incompatible with present version of ', &
                         'subroutine SUBREADNF'                           !
        STOP
    ENDIF
    IF(NRWORD_NF.NE.NRWORD)THEN
        WRITE(0,*)'READNF fatal error:'
        WRITE(0,*)'  word length=',NRWORD_NF,' in file',CFLENAME
        WRITE(0,*)'  word length=',NRWORD,' in subroutine READNF'
        STOP
    ENDIF
!*** diagnostic
!      write(0,*)'readnf ckpt 7, begin allocation'
!***
    ALLOCATE(CXEPS(1:NCOMP))
    ALLOCATE(ICOMP(1:NX,1:NY,1:NZ,1:3))
    ALLOCATE(CXPOL(1:NX,1:NY,1:NZ,1:3))
    ALLOCATE(CXESCA(1:NX,1:NY,1:NZ,1:3))
    ALLOCATE(CXEINC(1:NX,1:NY,1:NZ,1:3))
    ALLOCATE(CXADIA(1:NX,1:NY,1:NZ,1:3))
!*** diagnostic
!      write(0,*)'readnf ckpt 8, end allocation, begin reading arrays'
!***
    READ(IOBIN)CXEPS
!*** diagnostic
!      write(0,*)'readnf ckpt 9, have read cxeps'
!***
    READ(IOBIN)ICOMP
    READ(IOBIN)CXPOL
    READ(IOBIN)CXESCA
    READ(IOBIN)CXADIA
    IF(NRFLDB==1)THEN
        ALLOCATE(CXBINC(1:NX,1:NY,1:NZ,1:3))
        ALLOCATE(CXBSCA(1:NX,1:NY,1:NZ,1:3))
        READ(IOBIN)CXBSCA
    ENDIF
    CLOSE(IOBIN)

    DPHYS=AEFF*(4._WP*PI/(3._WP*NAT0))**(1._WP/3._WP)
    NXY=NX*NY
    XMIN=(X0(1)+1.-0.5001)*DPHYS
    XMAX=(X0(1)+NX+0.5001)*DPHYS
    YMIN=(X0(2)+1.-0.5001)*DPHYS
    YMAX=(X0(2)+NY+0.5001)*DPHYS
    ZMIN=(X0(3)+1.-0.5001)*DPHYS
    ZMAX=(X0(3)+NZ+0.5001)*DPHYS

!!  test wether
    NARGIN = iargc()
    
    IF(nargin<=0 .OR. nargin>3)THEN
        WRITE(IDVOUT,FMT='(A)')'getpar fatal error: the size of parameters should equal 1'
        STOP
    ELSEIF(nargin==1)THEN
        CALL getarg(1,FLAG)
        OFFSET=REAL(0)
        NSLICE=200
    ELSEIF(nargin==2)THEN
        CALL getarg(1,FLAG)
        CALL getarg(2,XOFFSET)
        READ(XOFFSET,*) OFFSET
        NSLICE=200
    ELSEIF(nargin==3)THEN
        CALL getarg(1,FLAG)
        CALL getarg(2,XOFFSET)
        CALL getarg(3,XNSLICE)
        READ(XOFFSET,*) OFFSET
        READ(XNSLICE,*) NSLICE
    ENDIF

    DDP=118
    OPEN(UNIT=DDP,FILE='ddpostprocess.par')
    WRITE(DDP,FMT='(A)') "'w000r000k000.E1'            = name of file with E stored"
    WRITE(DDP,FMT='(A)') "'VTRoutput'                  = prefix for name of VTR output files"
    
    !! Usage of WRITE FUNCTION https://zhidao.baidu.com/question/241532142196844644.html
    IF(FLAG=='x')THEN
        WRITE(SLICESETTING,FMT=1080) OFFSET,YMIN*0.99,ZMIN*0.99,OFFSET,YMAX*0.99,ZMAX*0.99,NSLICE,NSLICE,&
        XMIN,YMIN,ZMIN,XMAX,YMAX,ZMAX
        WRITE(DDP,FMT='(A)') "1   = IVTR (set to 1 to create VTR output)"
    ENDIF

    IF(FLAG=='y')THEN
        WRITE(SLICESETTING,FMT=1081) XMIN*0.99,OFFSET,ZMIN*0.99,XMAX*0.99,OFFSET,ZMAX*0.99,NSLICE,NSLICE,&
        XMIN,YMIN,ZMIN,XMAX,YMAX,ZMAX
        WRITE(DDP,FMT='(A)') "1   = IVTR (set to 1 to create VTR output)"
    ENDIF

    IF(FLAG=='z')THEN
        WRITE(SLICESETTING,FMT=1082) XMIN*0.99,YMIN*0.99,OFFSET,XMAX*0.99,YMAX*0.99,OFFSET,NSLICE,NSLICE,&
        XMIN,YMIN,ZMIN,XMAX,YMAX,ZMAX
        WRITE(DDP,FMT='(A)') "1   = IVTR (set to 1 to create VTR output)"
    ENDIF

    IF(FLAG=='a')THEN
        WRITE(SLICESETTING,FMT=1083) XMIN*0.99,YMIN*0.99,ZMIN*0.99,XMAX*0.99,YMAX*0.99,ZMAX*0.99,NSLICE,NSLICE,NSLICE,&
        XMIN,YMIN,ZMIN,XMAX,YMAX,ZMAX
        WRITE(DDP,FMT='(A)') "1   = IVTR (set to 1 to create VTR output)"
    ENDIF

    WRITE(DDP,FMT='(A)') "1   = ILINE (set to 1 to evaluate E along a line)"
	WRITE(DDP,FMT='(A)') adjustl(trim(SLICESETTING))

    IF(FLAG=='i')THEN
        WRITE(IDVOUT, '(A,F9.5,A,F9.5,A,F9.5)') 'XMIN',XMIN,' YMIN',YMIN,' ZMIN',ZMIN
        WRITE(IDVOUT, '(A,F9.5,A,F9.5,A,F9.5)') 'XMAX',XMAX,' YMAX',YMAX,' ZMAX',ZMAX
        WRITE(IDVOUT, '(A)') '>getpar i --> get the information of this program'
        WRITE(IDVOUT, '(A)') '>getpar a --> create 3d data'
        WRITE(IDVOUT, '(A)') '>getpar x/y/z --> create corresponding plane ddpostprocess.par'
        WRITE(IDVOUT, '(A)') '>getpar x/y/z offset --> create corresponding plane ddpostprocess.par with offset'
        WRITE(IDVOUT, '(A)') '>getpar x/y/z offset slice --> create corresponding plane ddpostprocess.par with offset and slice'
    ENDIF

    
    CLOSE(DDP)
    WRITE(IDVOUT,FMT='(A,A)') '>GETPAR create ddpostprocess.par successfully with getpar of ',FLAG



1080 FORMAT(6F9.5,' 1 ',2I4,' = XMIN(',F8.5,'),YMIN(',F8.5&
    '),ZMIN(',F8.5,'),XMAX(',F7.5,'),YMAX(',F7.5,'),ZMAX(',F7.5,'),NAA,NAB,NAC')

1081 FORMAT(6F9.5,' ',I4,' 1 ',I4,' = XMIN(',F8.5,'),YMIN(',F8.5&
    '),ZMIN(',F8.5,'),XMAX(',F7.5,'),YMAX(',F7.5,'),ZMAX(',F7.5,'),NAA,NAB,NAC')

1082 FORMAT(6F9.5,' ',2I4,' 1 = XMIN(',F8.5,'),YMIN(',F8.5&
    '),ZMIN(',F8.5,'),XMAX(',F7.5,'),YMAX(',F7.5,'),ZMAX(',F7.5,'),NAA,NAB,NAC')

1083 FORMAT(6F9.5,' ',3I4,' = XMIN(',F8.5,'),YMIN(',F8.5&
    '),ZMIN(',F8.5,'),XMAX(',F7.5,'),YMAX(',F7.5,'),ZMAX(',F7.5,'),NAA,NAB,NAC')
end program GETPAR
