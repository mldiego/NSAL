%% Learn a hybrid automata model with linear ODEs for each location

%% 1) Specify parameters (to be defined by user)
Time = false;
Ts  = 0.05;
sigma = 0.003;  
winlen = 10;
num_var = 2;
num_ud = 0;
num = 1; x = []; ud = []; 

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
ode = getAllLinearODEs(trace);
tode = toc(tode);
save('tode.mat','tode');

%% Find the linear inequalities and transitions for each cluster

% Define parameters
eta = 100000; % number of iterations 
lambda = 0.05; % tolerance 
% gamma = 10; %the least number of inliers
gamma = 3;

% find the linear inequaities
[trace,label_guard] = getLinearInequalities(trace, eta, lambda, gamma);

t2 = toc;
% get the prefix tree acceptor for each trace
pta_trace = getPrefixTreeAcceptor(trace);
% remove false pta
pta_trace = pta_filter(pta_trace);
t3 = toc;

%% Generate hybrid automata formats

% 1) Generate hyst model
getLinearHyst('automata_learning',label_guard, num_var, ode, pta_trace);
addpath(['..', filesep, '..', filesep, 'src',filesep,'hyst', filesep, 'src', filesep, 'matlab']);

% 2) Generate Stateflow model (MATLAB/Simulink/StateFlow)
try
    SpaceExToStateflow('automata_learning.xml');
catch
    warning("Conversion to Stateflow failed")
end

% 3) Generate CORA model (we use this for verification in NNV)
disp('Converting Hybrid Automaton from SpaceEx to CORA')
try
    spaceex2cora('automata_learning.xml',0,'automata_learning_sys','ex1_linear',pwd);
catch
    warning("Conversion to CORA failed.")
end


%% Helper Functions

% filter out PTAs
function pta_trace_new = pta_filter(pta_trace)
    % remove false pta
    label1s = extractfield(pta_trace,'label1');
    label2s = extractfield(pta_trace,'label2');
    id1s = extractfield(pta_trace,'id1');
    id2s = extractfield(pta_trace,'id2');
    nn = 1;
    while true
        if nn>length(pta_trace)
            break;
        end
        %flag1 = pta_trace(nn).times<=2;
        flag2 = ~ismember(pta_trace(nn).label1, label2s);
        flag3 = ~ismember(pta_trace(nn).label2, label1s);
        flag4 = ~ismember(pta_trace(nn).id1, id1s);
        flag5 = ~ismember(pta_trace(nn).id2, id2s);
        
        if (~ismember(pta_trace(nn).id1, id2s)) && (pta_trace(nn).id1~=1) || ~ismember(pta_trace(nn).id2, id1s)
            pta_trace(nn) = [];
        else
            nn = nn+1;
        end
    end
    pta_trace_new = pta_trace;
end

% remove redundant checkpoints due to noisy data
function trace = processNoiseData(xout, num_var)

    chpoints = [];
    for i = 1:num_var
        chpoints = union(chpoints, changepoint(xout(:,i)));
    end
    
    % remove redundant chpoints
    chpoints = filterindx(chpoints);
    xout_reduced= xout(:, 1:num_var);

    trace.x = xout_reduced;
    trace.chpoints = chpoints;
    trace.ud = [];
    trace.labels_num = []; 
    trace.labels_trace = [];  
end

% get changepoints based on upper and lower limits on the derivatives
function indx = changepoint(values)
    diffs = diff(values,2);
    indx = find(diffs<=-0.005|diffs>=0.005)+1;
    indx = union(1,[indx; length(values)]);
end

% filter changepoints that are too close to each other
function indx = filterindx(indx)
    n = 1;
    windw = 10; 
    while true
        if n >= length(indx)
            break;
        end
        id1 = indx(n);
        while true
            if n+1 >= length(indx)
                break;
            end
            id2 = indx(n+1);
            if id2-id1<=windw
                indx(n+1) = [];
            else
                break;
            end
        end
        n = n+1;
    end
end