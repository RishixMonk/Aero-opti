function [c,ceq] = Nonlincon(x)
    global Aircraft
    d2r = pi/180;
    
    %% Take-Off 
    S_TOFL = Aircraft.Performance.takeoff_runway_length; % Take-off field length in feets
    CL_max_TO = Aircraft.Aero.CL_max_TO;
    [~,rho,~,~] = ISA(0.3048*5000); % in kg/m^3 (at 5000 ft altitude required by the RFP)
    sigma = rho/1.225; 
    rho = rho*0.00194032; % converting to slugs/ft^3
    k1 = 0.0447;
    la=4;%bybass engine ratio
    k2 = 0.75*((5+la)/(4+la));
    ug = 0.025;
    
    % First Constrain
    c(1) =  (k1*Aircraft.Performance.WbyS)/(rho*(CL_max_TO*((k2*x(1))-ug)-0.72*Aircraft.Aero.C_D0_clean)) - S_TOFL;
   
   
    %% Landing (from Roskam 2)
    S_LFL = Aircraft.Performance.landing_runway_length;
    VA = sqrt(S_LFL/0.3);
    VS = VA / 1.2; % Stall Speed in kts;
    VS = VS * 1.688; % Stall Speed in ft/s
    CL_max_L = Aircraft.Aero.CL_max_L;
    [~,rho,~,~] = ISA(0.3048*5000); % in kg/m^3 (at 5000 ft altitude required by the RFP)
    rho = rho * 0.00194; % Density in lbs/ft^3; 0.00194 - converting kg/m^3 to slugs/ft^3
    
    % Second Constrain
     c(2) = Aircraft.Performance.WbyS/Aircraft.Weight.Landing_Takeoff - (VS^2)*CL_max_L*rho; % Second Constrain
    
    %% Climb Requirement
    CGR = 0.025;
    %Thrust_Factor = 0.85; %CHECK VALUE
    CD_o = Aircraft.Aero.C_D0_takeoff;
    C_L = Aircraft.Aero.CL_max - 0.2; % based on the guidelines from roskam 1 pg: 132
    L_by_D = C_L / (CD_o + C_L^2 / (pi * Aircraft.Wing.Aspect_Ratio * Aircraft.Aero.e_takeoff_flaps));
    
    % Third Constrain
    c(3) = 2*(CGR + L_by_D^(-1))-x(1);
    

    
    %% Cruise and Serivce Ceiling (from roskam 2)
    M = Aircraft.Performance.M_cruise;
    [P,rho,T,a] = ISA(30000*0.3048);
    rho = rho*0.0623;
    V = M*a/0.3048;
    q = 0.5*rho*V^2;
    q = q/32;
    alpha = (P*288.15)/(T*101325);
    
    beta = 0.96;
    
    %Fourth Constrain
   c(4) = ( Aircraft.Performance.WbyS*beta/(pi*Aircraft.Wing.Aspect_Ratio*Aircraft.Aero.e_clean*q) ...
            + ( (Aircraft.Aero.C_D0_clean + 0.003)*q)/(beta*Aircraft.Performance.WbyS) ) - x(1)*(alpha/beta);
    
    
    
    %% Critical Mach Number Constrain
  %  [~,rho,~,~] = ISA(Aircraft.Performance.cruise_altitude*0.3048);
  %  rho = rho * 0.001958; % Converting kg/m^3 to slugs/ft^3
  %  V = Aircraft.Performance.cruise_speed * 1.688; % Cruise speed in ft/s
    
   % C_L_cruise = Aircraft.Weight.Cruise_Takeoff * Aircraft.Weight.MTOW / ...
    %            ( Aircraft.Wing.S * 0.5 * rho * V^2);
           
   % Aircraft.Performance.M_critical = 0.87/cos(d2r * Aircraft.Wing.Sweep_hc)  ...
    %                - x(3)/( cos(d2r*Aircraft.Wing.Sweep_hc)^2 ) ...
     %               - C_L_cruise/( 10*cos(d2r*Aircraft.Wing.Sweep_hc)^3 ) - 0.108;
                
    % Sixth Constrain
  %  c(5) = (Aircraft.Performance.M_cruise - Aircraft.Performance.M_critical);            
    
    %% Equality Constrain
    y = Aircraft.Performance.V_takeoff * 1.668; % converting to ft/s from knots
    
    ESHP = 0.0076 * y^2 - 0.0662*y + 4591.1; % ESHP at takeoff condition at SL

    % Coefficients of the fitted model
    p00 =        4068;
    p10 =    -0.08207;
    p01 =       -0.42;
    p20 =   4.901e-07;
    p11 =  -5.266e-05;
    p02 =     0.01027;
    p21 =   -3.13e-10;
    p12 =   6.489e-08;
    p03 =   -5.71e-06;
    p22 =  -6.958e-13;
    p13 =  -1.014e-10;
    p04 =   1.654e-09;
    
    % Updating the p00 and thus updating the model 
    p00 = p00 - ESHP + Aircraft.Propulsion.thrust_per_engine; % 0.9 to ocnvert into takeoff condition
    
    alt = Aircraft.Performance.cruise_altitude;
    y = Aircraft.Performance.cruise_speed * 1.668; % Cruise Speed (in ft/s) 
    
    % Calculating the ESHP at cruise condition (normal settings)
    Aircraft.Performance.ESHP_cruise = p00 + p10*alt + p01*y + p20*alt^2 + p11*alt*y + p02*y^2 + p21*alt^2*y ...
                + p12*alt*y^2 + p03*y^3 + p22*alt^2*y^2 + p13*alt*y^3 + p04*y^4;

    % Calculating the thrust from one engine at cruise condition        
    T = 550 * Aircraft.Performance.ESHP_cruise * Aircraft.Propulsion.np_cruise / y; % 0.82 - propeller efficiency from roskam 1 pg: 14
    
    ceq(1) = Aircraft.Weight.MTOW * Aircraft.Weight.Cruise_Takeoff / (2 * T) - Aircraft.Aero.LbyD_max_cruise;            
    
    %ceq = 0;
    
end