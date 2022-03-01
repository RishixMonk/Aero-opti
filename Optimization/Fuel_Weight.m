%  Aircraft Fuel Weight Calculator for a given mission
%  ------------------------------------------------------------------------
%  Input : Aircraft structure datatpye.
%  Output : Aircraft sturcture datatype with updated Fuel Weight.
%  All units are in FPS System.
%  ------------------------------------------------------------------------
%  Mission Description:
%  Complete mission is divided into various segments. Mission Weight
%  Fraction for each segment is calculated. All the Weight weight fractions
%  are mutliplied to get ratio of weight of the airplane at the end of the
%  mission to start of the mission.
%  Segment No.		Name			
%  1                Engine Start & Warm Up			
%  2                Taxi to Runway			
%  3                Take Off			
%  4                Climb to cruise altitude			
%  5                Cruise to full range			
%  6                Descent			
%  7                Loiter for 16 min		
%  8                Dash		
%  9                Climb		
%  10               Cruise			
%  11               Descent					
%  ------------------------------------------------------------------------

function [Aircraft] = Fuel_Weight(Aircraft)
    np_cruise = 0.82;  % From Roskam Part 1 Pg: 1
    Aircraft.Propulsion.np_cruise=np_cruise;
     np_loiter = 0.77;  % From Roskam Part 1 Pg: 14
    Aircraft.Propulsion.np_loiter = np_loiter;
    
    C_bhp_cruise = efficiency(Aircraft.Performance.cruise_altitude, ...
                           Aircraft.Performance.cruise_speed );   % (in lbs/hp/hr) From efficiency function
    Aircraft.Propulsion.C_bhp_cruise = C_bhp_cruise;
                       
    % V_stall and V_takeoff calculation
    V_stall_take_off = sqrt( Aircraft.Performance.WbyS * 2 / 0.00238 / Aircraft.Aero.CL_max_TO );
    % 0.00238 - density in slugs / ft^3
    Aircraft.Performance.V_takeoff = 1.2 * V_stall_take_off / 1.67; % in knots
    % 1.67 - converting ft/s to knots
    Aircraft.Performance.M_takeoff = Aircraft.Performance.V_takeoff / 661.479;
    % 661.479 - speed of sound in knots at standard sea level condition
                       
    %% Mission Segment Weight Fractions %%
    
    W1byW_TO = 0.99;    % Mission Segement Weight Fraction for Engine Start & Warm Up     
    W2byW1 = 0.990;      % Mission Segement Weight Fraction for Taxi to Runway
    W3byW2 = 0.99;     % Mission Segement Weight Fraction for Take Off
    W4byW3=0.985;
    %%%% Mission Segement Weight Fraction for climb to cruise altitude %%%%
    %W4byW3 = (1.0065 - 0.0325 * Aircraft.Performance.M_cruise) ...
         %   /(1.0065 - 0.0325 * Aircraft.Performance.M_takeoff);      
    
    % Raymer Pg: 150 ; Eq: 6.9
    
    %%%%% Mission Segement Weight Fraction for cruise segment %%%%%
    W5byW4 = exp( -(Aircraft.Performance.cruise_range * 6076.115 * C_bhp_cruise) ...
            / ( 550 * np_cruise * Aircraft.Aero.LbyD_max_cruise * 3600 ) );
    
    Aircraft.Weight.Cruise_Takeoff = W5byW4 * W4byW3 * W3byW2 * W2byW1 * W1byW_TO;
        
    % Here, range in nautical miles is converted into feets by mutltiplying
    % 1852 (into meter) / 0.3048 (into feet) = 6076.115
    
    %%%%% descent %%%%% 
    W6byW5 = 0.99;
    
    %%%%% Mission Segement Weight Fraction for Loiter segment %%%%%
    [~,rho_loi,~,~] = ISA(Aircraft.Performance.loiter_altitude * 0.3048);
    [~,rho_cruise,~,~] = ISA(Aircraft.Performance.cruise_altitude * 0.3048);
    density_ratio = rho_loi / rho_cruise;
    Wloi_by_Wcr = W6byW5 * W5byW4; % Loiter weight to cruises weight ratio
    factor = sqrt( sqrt(3) * density_ratio / Wloi_by_Wcr );
    
    Aircraft.Performance.loiter_speed = 400; % in knots
    [~,~,~,speed_of_sound] = ISA(Aircraft.Performance.loiter_altitude * 0.3048); % Speed of Sound in m/s
    Aircraft.Performance.M_loiter = Aircraft.Performance.loiter_speed * 0.514 ...
                                            / speed_of_sound; % 0.514 - converting knots to m/s
    
    C_bhp_loiter = efficiency(Aircraft.Performance.loiter_altitude, ...
                           Aircraft.Performance.loiter_speed );
    
    Aircraft.Propulsion.C_bhp_loiter = C_bhp_loiter;
                       
    W7byW6 = exp( -(Aircraft.Performance.loiter * Aircraft.Performance.loiter_speed * 1.687 ...
                * C_bhp_loiter) / ( 550 * np_loiter * Aircraft.Aero.LbyD_max_loiter ));
    % 1.687 - converting knots to ft/s        
          
    %%%%% Mission Segement Weight Fraction for Climb to cruise altitude %%%%%
    % Raymer Pg: 150 ; Eq: 6.9
    W8byW7 = ( 1.0065 - 0.0325 * Aircraft.Performance.M_cruise ) ...
           / ( 1.0065 - 0.0325 * Aircraft.Performance.M_loiter );
    
    %%%%% Mission Segement Weight Fraction for cruise segment %%%%
    W9byW8 = exp( -(Aircraft.Performance.cruise2_range * 6076.115 * C_bhp_cruise) ...
            / ( 550 * np_cruise * Aircraft.Aero.LbyD_max_cruise * 3600 ) );
    % Here, range in nautical miles is converted into feets by mutltiplying
    % 1852 (into meter) / 0.3048 (into feet) = 6076.11
        
    %%%%% Descent %%%%%
    W10byW9 = 0.99;
    
    Aircraft.Weight.Landing_Takeoff = W1byW_TO*W2byW1*W3byW2*W4byW3*W5byW4*W6byW5*W7byW6*W8byW7*W9byW8*W10byW9;
    
    % V_stall and V_landing calculation
    V_stall_landing = sqrt( Aircraft.Performance.WbyS * Aircraft.Weight.Landing_Takeoff ...
                            * 2 / 0.00238 / Aircraft.Aero.CL_max_L ); % in ft/s
    % 0.00238 - sealevel density in slugs / ft^3
    Aircraft.Performance.V_landing = 1.3 * V_stall_landing / 1.67; % in knots
    % 1.67 - converting ft/s to knots
    Aircraft.Performance.M_landing = Aircraft.Performance.V_landing / 661.479;
    % 661.479 - speed of sound in knots at standard sea level condition
    
    %%%%% Reserve Fuel Mission - Climb %%%%%
    W11byW10 = ( 1.0065 - 0.0325 * Aircraft.Performance.M_loiter ) / ...
               ( 1.0065 - 0.0325 * Aircraft.Performance.M_landing);
    
    %%%%% Reserve Fuel Mission - loiter 45 mins %%%%%
    W12byW11 = exp( -(45/60 * Aircraft.Performance.loiter_speed * 1.687 ...
                * C_bhp_loiter) / ( 550 * np_loiter * Aircraft.Aero.LbyD_max_loiter ));
    
    %%%%% Descent %%%%%
    W13byW12 = 0.99;   
    
    %%%%% Taxi (Raymer) %%%%%
    W14byWW13 = 0.995;
    
    W14byW_TO = W1byW_TO*W2byW1*W3byW2*W4byW3*W5byW4*W6byW5*W7byW6*W8byW7* ...
                W9byW8*W10byW9*W11byW10*W12byW11*W13byW12*W14byWW13; 
           
    Aircraft.Weight.WfbyW_TO = 1.06*(1 - W14byW_TO);    % Fuel to MTOW ratio; 1% trapped fuel and 5% extra fuel for off-design condition
    Aircraft.Weight.Design_Gross_Weight_Fraction = W1byW_TO*W2byW1*W3byW2*W4byW3*W5byW4*W6byW5; %% ASK ???? %%%
    Aircraft.Weight.Design_Gross_Weight = Aircraft.Weight.MTOW * Aircraft.Weight.Design_Gross_Weight_Fraction;
    
    Aircraft.Weight.fuel_Weight = Aircraft.Weight.WfbyW_TO * Aircraft.Weight.MTOW;  % Fuel Weight
    
    %% Function to estimate the efficiency
    function C_bhp = efficiency(altitude, V)
        % Input: altitude (in ft) and velocity (in ft/s)
        % Output: efficiency (in lb fuel/ hour / ESHP)
        
        x = altitude; y = V;
        % Coefficients of the fitted curve
        p00 = 0.513;
        p10 = -2.635e-06;
        p01 =  0.0005461;
        p20 =  5.186e-11;
        p11 =  3.073e-09;
        p02 = -7.453e-06;
        p21 = -2.543e-13;
        p12 =  6.807e-12;
        p03 =  3.067e-08;
        p22 =  1.335e-15;
        p13 = -1.379e-13;
        p04 = -5.415e-11;
        p23 = -1.787e-18;
        p14 =  2.263e-16;
        p05 =  3.443e-14;
       
        % Fitted Model
      % C_bhp = p00 + p10*x + p01*y + p20*x^2 + p11*x*y + p02*y^2 + p21*x^2*y ...
                %    + p12*x*y^2 + p03*y^3 + p22*x^2*y^2 + p13*x*y^3 + p04*y^4 ...
                 %   + p23*x^2*y^3 + p14*x*y^4 + p05*y^5;
                  C_bhp=0.5;
    end
end