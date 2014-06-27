% optickle should NOT be in the path, set the paths in optickleTestConfig

%% Clear classes
clear classes

%%
addpath('testModels')
addpath('testClasses')

test1 = TickleTestOnOpt(@optFullIFO);
test2 = Tickle01TestOnOpt(@optFullIFO);
test3 = DetuneFPTest();

results = [];
for test = {test1 test2 test3}
    test = test{1};
    results = [results test.run()]; %#ok<AGROW>
end

disp(results);