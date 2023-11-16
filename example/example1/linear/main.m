%% Learn a hybrid automata model with linear ODEs for each location

%% 1) Specify parameters (to be defined by user)

% data related
% variable
Time = false;
Ts  = 0.05;
num_var = 2;
num_ud = 0;
% these 3 are fixed
num = 1; x = []; ud = []; 
sigma = 0.003; % error tolerance
winlen = 10; % window length for data vectors (shoul we fix it to 10?)

% Define parameters for linear inequality estimation
eta = 100000; % number of iterations 
lambda = 0.05; % tolerance 
% gamma = 10; %the least number of inliers
gamma = 3;

%% Load data

% Load data, process noise and detect changepoints
for i = 1:10
    load(['..', filesep, 'trainingdata' , filesep, 'run', int2str(i), '.mat']);
    trace_temp = processNoiseData(xout, num_var);
    trace(num) = trace_temp;
    x = [x; trace(num).x];
    ud = [ud; trace(num).ud];
    num = num+1; 
end

%% Divide data into traces and cluster them

tic
trace = clusterSegments(trace, x, ud, sigma, winlen);
toc
t1 = toc;

for n=1:length(trace)
    trace(n).labels_trace = [trace(n).labels_trace;0];
end

%% Estimate a linearODE model for each cluster

tode = tic;
ode = getAllLinearODEs(trace, Ts, num_var, num_ud);
tode = toc(tode);
save('tode.mat','tode');

%% Find the linear inequalities and transitions for each cluster

% find the linear inequaities
[trace,label_guard] = getLinearInequalities(trace, eta, lambda, gamma, num_var, Time);

t2 = toc;
% get the prefix tree acceptor for each trace
pta_trace = getPrefixTreeAcceptor(trace);
% remove false pta
pta_trace = filterPTA(pta_trace);
t3 = toc;

%% Generate hybrid automata formats

% 1) Generate hyst model
getLinearHyst('automata_learning',label_guard, num_var, ode, pta_trace);
% addpath(genpath(['./..', filesep, '..', filesep, '..', filesep, 'src',filesep,'hyst', filesep, 'src', filesep, 'matlab']));

% 2) Generate Stateflow model (MATLAB/Simulink/StateFlow)
% try % this is crashing matlab...
%     SpaceExToStateflow('automata_learning.xml');
% catch
%     warning("Conversion to Stateflow failed")
% end

% 3) Generate CORA model (we use this for verification in NNV)
% disp('Converting Hybrid Automaton from SpaceEx to CORA')
% try % This is throwing an error when converting invariants
%     spaceex2cora('automata_learning.xml',0,'automata_learning_sys','ex1_linear',pwd);
% catch
%     warning("Conversion to CORA failed.")
% end


