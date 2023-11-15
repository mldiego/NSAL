%% Generate a hybrid automata from trace data

% work in progress.....

% Initialize parameters
% global sigma num_var num_ud Ts winlen Time 
Time = false;  % ???
Ts  = 0.10;    % time sample (obtained from data)
sigma = 0.003; % this is for error tolerance
winlen = 10;   % related to segment data, not sure exactly what this is...
num_var = 6;   % number of state variables
num_ud = 6;    % number of inputs?

% initialize variables for indentifying trace data
num = 1; x = []; ud = []; 

%% Preprocess data

% Load data, process noise and detect changepoints
load(['..', filesep, 'trainingdata' , filesep, 'forward_identification_without_raw_data.mat']);

% Reshape data
y_test = y_test';
y_train = y_train';
u_test = u_test';
u_train = u_train';

% Generate raw traces from collected data
Trace = FnProcessNoiseData(y_train, num_var);


%% Divide segments using a clustering method

tic
Trace = FnClusterSegs(Trace, x, ud);
toc
t1 = toc;

% Assign a different label for each trace segment
for n=1:length(Trace)
    Trace(n).labels_trace = [Trace(n).labels_trace; 0];
end

%% Generate dynamics for each trace

tode = tic;
ode = FnEstODE(Trace);
tode = toc(tode);
save('tode.mat','tode'); % time to learn the dynamics for each trace


%% Find linear inequalities and guards for the automata locations

eta = 100000; % number of iterations 
lambda = 0.05; % tolerance 
% gamma = 10; %the least number of inliers
gamma = 3;
[Trace,label_guard] = FnLI(Trace, eta, lambda, gamma);
t2 = toc;
pta_trace = FnPTA(Trace);
pta_trace = pta_filter(pta_trace);
t3 = toc;


%% Generate the file containing the hybrid automata

% Generate the SpaceEx model (using hyst)
FnGenerateHyst('automata_learning',label_guard, num_var, ode, pta_trace);

addpath(['..', filesep, '..', filesep, 'src',filesep,'hyst', filesep, 'src', filesep, 'matlab']);

% Convert to Stateflow
try
    SpaceExToStateflow('automata_learning.xml');
catch
    warning('Failed to generate the Stateflow model.');
end

% Convert from SpaceEx to CORA (what NNV uses as well)
disp('Converting Hybrid Automaton from SpaceEx to CORA')
try
    spaceex2cora('automata_learning.xml',0,'automata_learning_sys','ex1_linear',pwd);
catch
    warning('Failed to generate the CORA model.');
end


%% Helper Functions
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

function trace = FnProcessNoiseData(xout, num_var)

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

function indx = changepoint(values)
    diffs = diff(values,2);
    indx = find(diffs<=-0.005|diffs>=0.005)+1;
    indx = union(1,[indx; length(values)]);
    
end

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