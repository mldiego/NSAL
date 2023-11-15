function FnComparePlot(mdl1, mdl2, x0, T, Ts)
% mdl1 = simulink model 1 (original model)
% mdl2 = simulink model 2 (inferred model)
% x0 = initial states
% T = final time for simulation
% Ts = time step

figure;
hold on;

sim(mdl1); % simulate model 1 (worskpace variable -> xout)

n = length(x0); % number of vars
t_vec = [0:Ts:T]'; % determine time vector

% initial condition for simulation, the model uses eg x1 = x0(1) for
% variable 1's initial condition

res = sim(mdl2, 'ReturnWorkspaceOutputs', 'on'); % simulate model 2

for j = 1 : n % plot traces vs time for each state variable

    % Create subplot
    subplot(n, 1, j);
    hold on;
    
    % Plot model 1 trace
    plot(t_vec, xout(:, j), 'b-');
    
    % plot model 2 trace
    temp_trace = res.ScopeData.signals(j).values();
    plot(t_vec, temp_trace, 'r-');
    
    % Create legend
    legend('Original system', 'Inferred automaton')
    ylabel(['x', int2str(j)])
    xlabel('Time/sec')
  
end

end 