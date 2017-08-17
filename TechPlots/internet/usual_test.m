function [ markcolor ] = usual_test( liststudied )
% This function permits to characterize if a float has a problem from its
% data.
 
if length(liststudied) > 0

    % Determine if there is an huge difference at the end.
    liststudied = abs(liststudied) ;
    finalpos = liststudied(end) ;

    % Delete the last 10% from the list
    liststudied = liststudied (1 : end-(floor(0.1 * length(liststudied))+1) ) ;
    moypos = mean(liststudied) ;

    % Compare the last value to +- 20% of the average value
    if finalpos > 1.1 * moypos  | finalpos < 0.9 * moypos
        if finalpos > 1.2 * moypos  | finalpos < 0.8 * moypos
            markcolor = 'red' ;
        else
            markcolor = [1 .5 0] ;
        end
    else
        markcolor = 'green' ;
    end

else
    markcolor = 'blue' ;
end

end