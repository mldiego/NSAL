function trace = processNoiseData(xout, num_var)
% remove redundant checkpoints due to noisy data

    chpoints = [];
    for i = 1:num_var
        chpoints = union(chpoints, getChangepoint(xout(:,i)));
    end
    
    % remove redundant chpoints
    chpoints = filterIndx(chpoints);
    xout_reduced= xout(:, 1:num_var);

    trace.x = xout_reduced;
    trace.chpoints = chpoints;
    trace.ud = [];
    trace.labels_num = []; 
    trace.labels_trace = [];
    
end

