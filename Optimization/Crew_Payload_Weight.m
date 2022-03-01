%  Aircraft Payload & Crew Weight Calculation
%  ------------------------------------------------------------------------
%  Input : Aircraft structure datatpye.
%  Output : Aircraft sturcture datatype with appended payload data.
%  All units are in FPS System.

function Aircraft = Crew_Payload_Weight(Aircraft)

    %%% Crew
    Aircraft.Crew = 4;
    Aircraft.Weight.person = 200;
    
    %%% Fire Retardant
    Aircraft.Weight.retardant = 66720;%(8000 gal to lbs)
    
    %%% Calculating weight of total payload and crew
    Aircraft.Weight.payload = Aircraft.Weight.retardant;
                    
    Aircraft.Weight.crew =  Aircraft.Weight.person * Aircraft.Crew;                

end