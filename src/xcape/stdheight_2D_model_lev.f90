!FILE: STDHEIGHT.F
!-----------------------------------------------------------------------
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!-----------------------------------------------------------------------
      SUBROUTINE loop_stdheight_ml(P,T,Td,Ps,Ts,Tds,Hin,NK,NX,H,Hs)
      !f2py threadsafe
      !f2py intent(out) :: H
      IMPLICIT NONE
      INTEGER, INTENT(IN) :: NK,NX
      INTEGER :: i
      DOUBLE PRECISION, DIMENSION(NK,NX), INTENT(IN) :: P,T,Td
      DOUBLE PRECISION, DIMENSION(NX), INTENT(IN) :: Ps,Ts,Tds
      DOUBLE PRECISION, DIMENSION(NX), INTENT(IN) :: Hin
      DOUBLE PRECISION, DIMENSION(NK,NX), INTENT(OUT) :: H
      DOUBLE PRECISION, DIMENSION(NX), INTENT(OUT) :: Hs

      do i = 1, NX
          call stdheight_ml(P(:,i),T(:,i),Td(:,i),Ps(i),Ts(i),Tds(i),Hin(i),NK,&
                        &H(:,i),Hs(i))
      enddo
      return
      end subroutine loop_stdheight_ml


!*********************************************************
!Fast FORTRAN subroutine to calculate
!Geopotential Height of an Isothermic layer,
!using the ISA by vertically integrating the
!hydrostatic balance equation with the density expressed
!through the perfect gas law.
!Written by John T. Allen July 2015, Last Updated Jan 2016
!*********************************************************

      SUBROUTINE stdheight_ml(P,T,Td,Ps,Ts,Tds,Hin,NK,H,Hs)
      !f2py threadsafe
      !f2py intent(out) :: H

      IMPLICIT NONE
      INTEGER, INTENT(IN) :: NK
      INTEGER :: k, NK_ALL, k_ALL
      DOUBLE PRECISION, DIMENSION(NK), INTENT(IN) :: P,T,Td
      DOUBLE PRECISION, INTENT(IN) :: Ps,Ts,Tds
      DOUBLE PRECISION, DIMENSION(NK) :: Tv
      DOUBLE PRECISION :: Tvs
      DOUBLE PRECISION :: Tin,Tdin,E,w
      DOUBLE PRECISION, INTENT(IN) :: Hin
      DOUBLE PRECISION, DIMENSION(NK), INTENT(OUT) :: H
      DOUBLE PRECISION, INTENT(OUT) :: Hs

      DOUBLE PRECISION, PARAMETER :: R=287.04
      DOUBLE PRECISION, PARAMETER :: g=-9.80665
      !INTEGER, PARAMETER :: n = 10
      DOUBLE PRECISION, PARAMETER :: eps = 0.6219800858985514
      !PARAMETER (R=287.04,g=-9.80665)
      !Calculate Virtual Temperatures at the Two Levels and the mean of these two values.
      !Calculate Height using the Hyposometric Equation  RdTvmean/g (ln(p1/p2)) = z2-z1

      ! number of levels 3D + surface
      NK_ALL = NK + 1

      ! if surface level, use surface temperature
      Tin=Ts+273.15
      !W calculation starting from dewpoint
      Tdin = Tds+273.15
      !E = 6.112*exp((17.67*(Tdin-273.15))/(Tdin-29.65))
      E = 6.112*exp((53.49-(6808/Tdin)-5.09*log(Tdin)))
      w = eps*(E/(Ps-E))
      !Alt W calculation starting from specific humidity
      ! w = (qs/1000)/(1-(qs/1000))
      !Now Calculate Tv correctly:
      Tvs = Tin*((w+eps)/(eps*(1+w)))
      !Old Incorect Tv
      !Tvs=Tin/(1-0.379*(6.11*10*((7.5*Tds)/ &
      !(237.7+Tds))/Ps))
      ! loop along vertical levels 3D = NK
      DO k = 1, NK
        Tin=T(k)+273.15
        !Calculate w for each layer
        Tdin = Td(k)+273.15
        ! E = 6.112*exp((17.67*(Tdin-273.15))/(Tdin-29.65))
        E = 6.112*exp((53.49-(6808/Tdin)-5.09*log(Tdin)))

        w=eps*(E/(P(k)-E))
        !Alt Calc w each layer
        ! w= (qs/1000)/(1-(qs/1000))
        !Calculate Virtual Temperatures for a surface + 3d element
        Tv(k) = Tin*((w+eps)/(eps*(1+w)))
        !Incorrect Old Method
        !Tv(k)=Tin/(1-0.379*(6.11*10*((7.5*Td(k))/ &
        !(237.7+Td(k)))/P(k)))
      ENDDO
        !Now Integrate along the Hypsometric Equation

      DO k_ALL = 1, NK_ALL
        k = k_ALL-1
        ! for surface height, that is actually equal to Hin (either topography or 2m)
        IF (k_ALL .EQ. 1) THEN
          Hs=Hin
        ELSEIF (k_ALL .EQ. 2) THEN
          ! for k = 2 it uses Hs and Tvs for the layer below
          ! variables from 3D use k_ALL-1 as index
          ! m = (Tv(k)-Tvs)/(log(P(k))-log(Ps))
          ! b = Tvs-m*log(Ps)
          ! call Trapz(m*x+b,log(Ps),log(P(k)),Tvp,n)
          ! H(k)=Hs-((R/g)*Tvp)
          ! original implementation assuming mean value theorem
          H(k)=Hs+((R*((Tv(k)+Tvs)/2)/g))*(log(P(k)/Ps))
        ELSE
          ! for k >= 3 it uses only 3D variables
          ! variables from 3D use k-1 as index
          ! m = (Tv(k)-Tv(k-1))/(log(P(k))-log(P(k-1)))
          ! b = Tv(k)-m*log(P(k))
          ! call Trapz(Tv,log(P(k-1)),log(P(k)),Tvp,n)
          ! H(k) = H(k-1)+((R/g)*Tvp)
          H(k)=H(k-1)+((R*((Tv(k)+Tv(k-1))/2)/g))*(log(P(k)/P(k-1)))
        ENDIF
      ENDDO

      RETURN
      END SUBROUTINE stdheight_ml
      !END OF FILE STDHEIGHT.F
