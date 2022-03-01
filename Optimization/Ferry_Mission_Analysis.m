function Aircraft = Ferry_Mission_Analysis(Aircraft)
    % This script analyses the optimized airplane for the ferry mission as
    % required by the RFP.
    %  ------------------------------------------------------------------------
    %  Mission Description:
    %  Complete mission is divided into various segments. Mission Weight
    %  Fraction for each segment is calculated. All the Weight weight fractions
    %  are mutliplied to get ratio of weight of the airplane at the end of the
    %  mission to start of the mission.
    %  Segment No.		Name			
    %  1                Engine Start & Warm Up			
    %  2                Taxi to Runway			
    %  3                Take Off ; less than 4,000 ft			
    %  4                Climb to cruise altitude 			
    %  5                Cruise for 900 nmi ; >= 18,000 ft
    %  6                Descent		
    %  7                Climb to 3,000 ft (part of reserves)
    %  8                Loiter for 45 minutes (part of reserves)		
    %  9                Descent 			
    %  10               Taxi					
    %  ------------------------------------------------------------------------
    %  Note that the payload is only 60% of the total.
    
    W1byW_TO = 0.99;    % Mission Segement Weight Fraction for Engine Start & Warm Up     
    W2byW1 = 0.995;      % Mission Segement Weight Fraction for Taxi to Runway
    W3byW2 = 0.99;     % Mission Segement Weight Fraction for Take Off
    
    %%%% Mission Segement Weight Fraction for climb to cruise altitude %%%%
    W4byW3 = (1.0065 - 0.0325 * Aircraft.Performance.M_cruise) ...
            /(1.0065 - 0.0325 * Aircraft.Performance.M_takeoff);
    
    ferry_cruise_range = Aircraft.Performance.total_ferry_range - Aircraft.Performance.climb_range;
        
    %%%%% Mission Segement Weight Fraction for cruise segment %%%%%
    W5byW4 = exp( -(ferry_cruise_range * 6076.115 * Aircraft.Propulsion.C_bhp_cruise) ...
            / ( 550 * Aircraft.Propulsion.np_cruise * Aircraft.Aero.LbyD_max_cruise * 3600 ) );
    % Here, range in nautical miles is converted into feets by mutltiplying
    % 1852 (into meter) / 0.3048 (into feet) = 6076.115
    
    %%%%% descent %%%%% 
    W6byW5 = 0.99;
    
    %%%%% Reserve Fuel Mission - Climb %%%%%
    W7byW6 = ( 1.0065 - 0.0325 * Aircraft.Performance.M_loiter ) / ...
               ( 1.0065 - 0.0325 * Aircraft.Performance.M_landing);
           
    %%%%% Reserve Fuel Mission - loiter 45 mins %%%%%
    W8byW7 = exp( -(45/60 * Aircraft.Performance.loiter_speed * 1.687 * Aircraft.Propulsion.C_bhp_loiter) ...
                / ( 550 * Aircraft.Propulsion.np_loiter * Aircraft.Aero.LbyD_max_loiter ));
            
    %%%%% descent %%%%% 
    W9byW8 = 0.99;
    
    %%%%% Taxi (Raymer) %%%%%
    W10byW9 = 0.995;
    
    W10byW_TO = W1byW_TO*W2byW1*W3byW2*W4byW3*W5byW4*W6byW5*W7byW6*W8byW7* ...
                W9byW8*W10byW9; 
           
    fuel_MTOW = 1.06*(1 - W10byW_TO);    % Fuel to MTOW ratio
    
    MTOW_ferry = 15000;  % Initial Guess
    error = 1; % Dummy value to start the while loop
    
    while error > 0.005
    
        error = MTOW_ferry;
        
        MTOW_ferry = Aircraft.Weight.crew + 0.6 * Aircraft.Weight.payload + fuel_MTOW * MTOW_ferry ...
                               + Aircraft.Weight.empty_weight;

        error = abs(error - MTOW_ferry);
    end
    
    MTOW_ferry * fuel_MTOW
end