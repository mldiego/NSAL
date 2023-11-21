%% Generate nonlinear HAs for all examples


%%

disp('Generating HAs for Example 1');

cd example1;
cd nonlinear;

run learn.m;

cd ..;
cd ..;

%%

disp('Generating HAs for Example 2');

cd example2;
cd nonlinear;

run learn.m;

cd ..;
cd ..;

%%

disp('Generating HAs for 2-dimensional stable system');
cd stable2d;
cd nonlinear;

run learn.m;

cd ..;
cd ..;

%%

disp('Generating HAs for 3-dimensional stable system');
cd stable3d;
cd nonlinear;

run learn.m;

cd ..;
cd ..;

disp('All linear experiments are conducted');
