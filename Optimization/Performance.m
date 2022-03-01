
%  Performance Calculations
%  ------------------------------------------------------------------------
%  Input : Aircraft structure datatpye.
%  Output : Aircraft sturcture datatype with appended Perfomance Parameters.
%  All units are in FPS System.
%  ------------------------------------------------------------------------

function Aircraft = Performance(Aircraft)
    Aircraft.Performance.total_range = 800; % total cruise in nautical miles
    Aircraft.Performance.total_ferry_range = 3000; % total ferry cruise in nmi
    Aircraft.Performance.total_cruise_descent_time = 20; % total time for climb and cruise in minutes
    
    Aircraft.Performance.takeoff_runway_length = 5000;  % in ft
    Aircraft.Performance.landing_runway_length = 5000;  % in ft
    
   Aircraft.Performance.loiter = 0.27;   % loiter time in hours
  Aircraft.Performance.loiter_altitude = 300; % Loiter altitude as required by the RFP in ft
    
    Aircraft.Vndiagram.n_ult =4.5; 
    
    Aircraft.Performance.minimum_service_ceiling = 30000; % in ft, required by the RF
    Aircraft.Performance.CL_max_TO= 1.3;
    Aircraft.Performance.CL_max_L=2.0;
end