%% Learn a hybrid automata model with linear ODEs for each location

%% 1) Specify parameters (to be defined by user)

% data related
% variable
time = false;
Ts  = 0.01; % time step
sigma = 0.006; % error tolerance
winlen = 10;  % window length for data vectors (shoul we fix it to 10?)

% Define parameters for linear inequality estimation
eta = 100000; % number of iterations 
lambda = 0.05; % tolerance 
% gamma = 10; %the least number of inliers
gamma = 3;

% dynamics to use for each hybrid automata location
odeType = 'linear';


%% 2) Load data

N = 10; % number of data runs

% Load raw data
data = struct;
for i = 1:N
    load(['..', filesep, 'trainingdata' , filesep, 'run', int2str(i), '.mat']);
    data(i).x = xout(:,1:2);
    data(i).u = [];
end


%% 3) Run general function to learn any hybrid automata

% Learn hybrid automata
learnHybridAutomata(data, odeType, Ts, time, sigma, winlen, eta, lambda, gamma);
