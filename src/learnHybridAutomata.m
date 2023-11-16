function learnHybridAutomata(data, odeType, Ts, sigma, winlen)

% Input Parameters
% odeType = {linear, nonlinear, neural};
% data related
% variable
% Time = true/false;
% Ts  = 0.05;
% num_var = 2; number of state variables in the data
% num_ud = 0; number of inputs
% sigma = 0.003; % error tolerance
% winlen = 10; % window length for data vectors (shoul we fix it to 10?)

%
% Initialize variables
num = 1; x = []; ud = []; 

% If undefined, these are the default values
% Define parameters for linear inequality estimation
% eta = 100000; % number of iterations 
% lambda = 0.05; % tolerance (although example 2 -> 0.005);
% gamma = 3; %the least number of inliers


% Parameters needed for nonlinear


% Parameters needed for neuralodes



%% 1) Load data, process noise and detect changepoints

N = length(data); % must be a cell array containing data with in a struct form
% get data size
xSample = data{1}.x;
num_var = size(xSample,2); % get number of variables
% get input size
uSample = data{1}.u;
if isempty(uSample)
    num_ud = 0;
else
    num_ud = size(uSample, 2);
end

% process every data trace collected
for i = 1:N
    xout = data{i}.x; % state data
    trace_temp = processNoiseData(xout, num_var);
    trace(num) = trace_temp;
    x = [x; trace(num).x];
    ud = [ud; trace(num).ud];
    num = num+1; 
end

%% 2) Divide data into traces and cluster them

tic
trace = clusterSegments(trace, x, ud, sigma, winlen);
toc
t1 = toc;

for n=1:length(trace)
    trace(n).labels_trace = [trace(n).labels_trace;0];
end

%% 3) Learn dynamics for each trace cluster

tode = tic;

% Estimate a linearODE model for each cluster
if strcmp(odeType, 'linear')
    ode = getAllLinearODEs(trace, Ts, num_var, num_ud);
% Estimate a nonlinearODE model for each cluster
elseif strcmp(odeType, 'nonlinear')
    error('Working on it...')
% % Estimate a neuralODE model for each cluster 
elseif strcmp(odeType, 'neural')
    error('Work in progress...')
else
    error('Wrong dynamics specified.')
end
    
tode = toc(tode);
% save('tode.mat','tode');

%% 4) Find the linear inequalities and transitions for each cluster

% find the linear inequaities
[trace,label_guard] = getLinearInequalities(trace, eta, lambda, gamma, num_var, Time);

t2 = toc;
% get the prefix tree acceptor for each trace
pta_trace = getPrefixTreeAcceptor(trace);
% remove false pta
pta_trace = filterPTA(pta_trace);
t3 = toc;


%% 5) Generate hybrid automata formats

if strcmp(odeType, 'linear')
    getLinearHyst('automata_learning',label_guard, num_var, ode, pta_trace);
elseif strcmp(odeType, 'nonlinear')
    getNonlinearHyst('automata_learning',label_guard, num_var, ode, pta_trace);
elseif strcmp(odeType, 'neural')
    getNeuralODEHyst('automata_learning',label_guard, num_var, ode, pta_trace);
else
    error('Wrong dynamics specified.')
end


end

