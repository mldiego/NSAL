function indx = getChangepoint(values)
% get changepoints based on upper and lower limits on the derivatives
% Limits are set to <=-0.005 && >=0.005, but could make the limits 
% be arguments to the function for more flexibility

    diffs = diff(values,2);
    indx = find(diffs<=-0.005|diffs>=0.005)+1;
    indx = union(1,[indx; length(values)]);
    
end

