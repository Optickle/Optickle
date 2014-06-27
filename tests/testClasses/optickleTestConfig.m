function config = optickleTestConfig()
    % referenceType can be 'Files' or 'Path'
    %config.referenceType = 'Path';
    %config.referencePath = '~/tmp/Optickle';
    config.referenceType = 'Files';
    config.referencePath = './referenceFiles/Optickle1';
    config.calculationPath = '~/tmp/Optickle';
    config.residualSize = 5e-5;
    config.errorThreshold = 1e-6;
end