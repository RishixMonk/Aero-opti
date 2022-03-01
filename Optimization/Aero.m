%  Aircraft Aero Estimator
%  ------------------------------------------------------------------------
%  Input : Aircraft structure datatpye.
%  Output : Aircraft sturcture datatype with required variables appended.
%  Aero Polar : C_D = C_D0 + K*C_L^2
%  All units are in FPS System.
%  ------------------------------------------------------------------------

function Aircraft = Aero(Aircraft)
    %% Zero Lift Drag Estimation 'C_D_0' (Method from Raymer): %%%%%%
    % Regression Coefficients which relate MOTW and Wetted Area
    % Roskam Part 1 - Table 3.5 Pg. No. 122
        % d = 0.7316;    %changes made%   
       % c=0.1628
        c = 0.0199;

        d = 0.7531;
       

    % Regression Coefficients which relate Parasite Area and Wetted Area
    % Roskam Part 1 - Table 3.4 Pg. No. 122 cf = 0.003
        a = -2.5229;          %no changes
        b = 1;

    Aircraft.Aero.Swet = 10^(c + d*log10(Aircraft.Weight.MTOW));
    f = 10^(a + b*log10(Aircraft.Aero.Swet));
    Aircraft.Aero.C_D0_clean = f/Aircraft.Wing.S; % From Roskam Part 1 Eq 3.20 Pg: 118
    Aircraft.Aero.C_D0_takeoff = Aircraft.Aero.C_D0_clean + 0.015;  % C_D0 when take-off flaps deployed
    Aircraft.Aero.C_D0_landing = Aircraft.Aero.C_D0_clean + 0.065;  % C_D0 when landing flaps deployed
    
    %% L/D Estimation:
    K_LD = 15.5;  % Factor from Raymer Pg 40 Eq: 3.12
    Aircraft.Aero.LbyD_max_cruise = K_LD*sqrt(Aircraft.Wing.Aspect_Ratio * Aircraft.Wing.S/Aircraft.Aero.Swet);   % Cruise L/D
    Aircraft.Aero.LbyD_max_loiter = 0.866*Aircraft.Aero.LbyD_max_cruise;   % Loiter L/D
    
    %% CL_max values in various configurations (from Roskam 1 Pg: 91)
    Aircraft.Aero.CL_max = 1.5;
    Aircraft.Aero.CL_max_TO = 1.9;         %nochanges
    Aircraft.Aero.CL_max_L = 2.9;
    
    %% Few Performance Calculation
    Aircraft.Propulsion.np_cruise = 0.82;
  %{  
n_p = Aircraft.Propulsion.np_cruise;
    factor = 1.345 * (Aircraft.Wing.Aspect_Ratio * 0.7)^0.75 ... 
                / ( Aircraft.Aero.C_D0_clean^0.25 ); % 0.7 is the 'e' assumed here.
    RCP = n_p / Aircraft.Performance.TbyW - sqrt(Aircraft.Performance.WbyS) / (19 * factor);
    Aircraft.Performance.RC = 33000 * RCP;   % ft/min
    C_L = Aircraft.Aero.CL_max - 0.2; % based on the guidelines from roskam 1 pg: 132
    C_D_0 = Aircraft.Aero.C_D0_clean; 
    L_by_D = C_L / (C_D_0 + C_L^2 / (pi * Aircraft.Wing.Aspect_Ratio * 0.7)); % 0.75 is the 'e' assumed here.
    
    Aircraft.Performance.CGRP = 18.97 * n_p / (Aircraft.Performance.WbyS^0.5/Aircraft.Performance.TbyW);
    
    Aircraft.Performance.CGR = Aircraft.Performance.CGRP * sqrt(C_L) - 1 / L_by_D;
    
    
    horizontal_speed = Aircraft.Performance.RC * 0.00987 / tan(Aircraft.Performance.CGR);
    % knots (average of available data from gudmundson Pg: 843)
    
    Aircraft.Performance.horizontal_speed = horizontal_speed;
    Aircraft.Performance.climb_time = (Aircraft.Performance.cruise_altitude - 0) / Aircraft.Performance.RC;   % in minutes
    Aircraft.Performance.climb_range = horizontal_speed * Aircraft.Performance.climb_time / 60;   % in nautical miles
    Aircraft.Performance.descent_time = (Aircraft.Performance.cruise_altitude - 300) / Aircraft.Performance.RC;
    Aircraft.Performance.descent_range = horizontal_speed * Aircraft.Performance.descent_time / 60;
    
    Aircraft.Performance.cruise_range = Aircraft.Performance.total_range - ...
                                    Aircraft.Performance.climb_range; % in nautical miles
    Aircraft.Performance.cruise_speed = Aircraft.Performance.cruise_range / ...
          (Aircraft.Performance.cruise_descent_time) ...
          * 60; % in knots (this is a requirement set by RFP)
    
    [~,~,~,speed_of_sound] = ISA(Aircraft.Performance.cruise_altitude * 0.3048); % Speed of Sound in m/s
    Aircraft.Performance.M_cruise = Aircraft.Performance.cruise_speed ....
        * 1.852 * 5 / 18 / speed_of_sound; % Mach number at cruise
    
    climb_time = (Aircraft.Performance.cruise_altitude - 3000) / Aircraft.Performance.RC;   % in minutes
    climb_range = horizontal_speed * climb_time / 60;   % in nautical miles
    Aircraft.Performance.cruise2_range = Aircraft.Performance.total_range - climb_range; % in nautical mile 
  %}
    Aircraft.Performance.cruise2_range=400;
    Aircraft.Performance.cruise_range=400;
    [~,~,~,speed_of_sound] = ISA(Aircraft.Performance.cruise_altitude * 0.3048); % Speed of Sound in m/s
    Aircraft.Performance.cruise_speed=Aircraft.Performance.M_cruise*18*speed_of_sound/ (1.852 * 5 );
         % Mach number at cruise
    %% Oswald Efficiency Factor Estimation 'e' (Method from Nita and ):    
    del_lamda = 0.45 * exp( -0.375 * pi / 180 * Aircraft.Wing.Sweep_qc ) - 0.357;
    lamda_dash = Aircraft.Wing.taper_ratio - del_lamda;
    k = 0.0524*lamda_dash^4 - 0.15*lamda_dash^3 + 0.166*lamda_dash^2 - 0.0706*lamda_dash + 0.0119;
    et = 1 / (1 + Aircraft.Wing.Aspect_Ratio * k);  % Term for taper ratio, aspect ratio and sweep angle
    eb = 1 - 2*( Aircraft.Fuselage.height/Aircraft.Wing.b )^2;    % Fuselage and span correction
    ed = 0.804; %   correction factor 
    em = 1 - 1.52 * 1e-4 * (Aircraft.Performance.M_cruise/0.3 - 1)^10.82;    % Mach number correction factor
    %Aircraft.Aero.e_clean = et * eb * ed * em;  % Oswald efficiency factor
   %Aircraft.Aero.e_takeoff_flaps = Aircraft.Aero.e_clean / em - 0.05; % dividing by em since mach number < 0.3
   % Aircraft.Aero.e_landing_flaps = Aircraft.Aero.e_clean / em - 0.1; % dividing by em since mach number < 0.3
    Aircraft.Aero.e_clean = 0.75;
    Aircraft.Aero.e_takeoff_flaps = 0.7;
    Aircraft.Aero.e_landing_flaps = 0.65;
end