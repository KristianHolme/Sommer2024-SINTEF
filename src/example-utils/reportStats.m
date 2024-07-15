function reportStats(reports, names, varargin)
opt = struct('plottime', true, ...
    'nonlineardetails', true, ...
    'nonlinearComparison', true, ...
    'lineardetails', true,...
    'title', '', ...
    'savefolder', '', ...
    'batchname', '');
%TODO: add cutting stats

opt = merge_options(opt, varargin{:});
if isempty(opt.title) && ~isempty(opt.batchname)
    opt.title = opt.batchname;
end
opt.batchname = replace(opt.batchname, ' ', '_');

num_reports = numel(reports);

set(groot, 'defaultLineLineWidth', 2);
% set(groot, 'DefaultTextFontSize', 22);
set(0, 'DefaultAxesFontSize', 12);

%Formatting
if isa(reports{1}, 'ResultHandler')
    num_report_steps = numelData(reports{1});
    new_reports = cell(num_reports, 1);
    for irep = 1:num_reports
        report = reports{irep};
        new_reports{irep} = struct();
        new_reports{irep}.ReservoirTime = nan(num_report_steps, 1);
        new_reports{irep}.Converged = nan(num_report_steps, 1);
        new_reports{irep}.Iterations = nan(num_report_steps, 1);
        new_reports{irep}.SimulationTime = nan(num_report_steps, 1);
        new_reports{irep}.ControlstepReports = cell(num_report_steps, 1);
        for istep = 1:num_report_steps
            report_step = report{istep};
            new_reports{irep}.ControlstepReports{istep} = report_step;
            stepreports = report_step.StepReports;
           

            new_reports{irep}.ReservoirTime(istep) = stepreports{end}.LocalTime;
            new_reports{irep}.Converged(istep)  = report_step.Converged;
            new_reports{irep}.Iterations(istep) = report_step.Iterations;
            new_reports{irep}.SimulationTime(istep) = report_step.WallTime;
        end
    end
    reports = new_reports;
end

num_steps = numel(reports{1}.ReservoirTime);
if max(reports{1}.ReservoirTime) > 10*year
    xscaling = year;
    unit = 'y';
elseif max(reports{1}.ReservoirTime) > 10*day
    xscaling = day;
    unit = 'd';
elseif max(reports{1}.ReservoirTime) >10*hour
    xscaling = hour;
    unit = 'h';
else
    xscaling = 1;
    unit = 's';
end

if opt.plottime
    figure('name', opt.title);
    for irep = 1:num_reports
        report = reports{irep};
        plot(report.ReservoirTime ./ xscaling, cumsum(report.SimulationTime));hold on;
    end
    xlabel(sprintf('Reservoir Time (%s)', unit));
    ylabel("Simulation Time (s)");
    legend(names, Location="best");
    % title(opt.title);
    grid;
    hold off;
    tightfig;
    if ~isempty(opt.savefolder)
        pth = fullfile(opt.savefolder, 'time', [opt.batchname, '.pdf']);
        [dirname, ~, ~] = fileparts(pth);
        if ~exist(dirname, 'dir')
            mkdir(dirname);
        end
        saveas(gcf, pth);
        saveas(gcf, replace(pth, '.pdf', '.png'));
    end
end

% num_report_steps = numel(reports{1}.Iterations);
% if opt.nonlineardetails
%     nlits = cell(num_report_steps,1);
%     for irep = 1:num_reports
%        report = reports{irep};
%        for istep = 1:num_report_steps
%            controlstepReport = report.ControlstepReport{istep};
%             nlits{irep}(istep) = controlstepReport.Iterations;
%        end
% 
%     end
% 
% end
if opt.nonlinearComparison
    figure('Name',opt.title);
    for irep = 1:num_reports
        report = reports{irep};
        plot(report.ReservoirTime ./xscaling, cumsum(report.Iterations));hold on;
    end
    xlabel(sprintf('Reservoir Time (%s)', unit));
    ylabel("Nonlinear iterations");
    legend(names, Location="best");
    % title(opt.title);
    grid;
    hold off;
    tightfig;
    if ~isempty(opt.savefolder)
        pth = fullfile(opt.savefolder, 'nonlinearIterations', [opt.batchname, '.pdf']);
        [dirname, ~, ~] = fileparts(pth);
        if ~exist(dirname, 'dir')
            mkdir(dirname);
        end
        saveas(gcf, pth);
        saveas(gcf, replace(pth, '.pdf', '.png'));
    end
end

if opt.lineardetails
    linearSolutionTime = zeros(num_steps, num_reports);
    preparationTime = zeros(num_steps, num_reports);
    postProcessTime = zeros(num_steps, num_reports);
    for ireport = 1:num_reports
        for i_step = 1:num_steps
            controlStepReport = reports{ireport}.ControlstepReports{i_step};
            stepReports = controlStepReport.StepReports;
            for i_stepReport = 1:numel(stepReports)
                nonlinearReport = stepReports{i_stepReport}.NonlinearReport;
                for i_nlRep = 1:(numel(nonlinearReport)-1)
                    linearSolutionTime(i_step, ireport) = linearSolutionTime(i_step, ireport)...
                        + nonlinearReport{i_nlRep}.LinearSolver.LinearSolutionTime;

                    preparationTime(i_step, ireport) = preparationTime(i_step, ireport)...
                        + nonlinearReport{i_nlRep}.LinearSolver.PreparationTime;

                    postProcessTime(i_step, ireport) = postProcessTime(i_step, ireport)...
                        + nonlinearReport{i_nlRep}.LinearSolver.PostProcessTime;
                end
            end
        end
    end

    figure('Name',opt.title);
    for irep = 1:num_reports
        report = reports{irep};
        plot(report.ReservoirTime ./xscaling, cumsum(linearSolutionTime(:,irep)));hold on;
    end
    xlabel(sprintf('Reservoir Time (%s)', unit));
    ylabel("Linear solution time (s)");
    legend(names, Location="best");
    % title(opt.title);
    grid;
    hold off;
    tightfig;
    if ~isempty(opt.savefolder)
        pth = fullfile(opt.savefolder, 'linearSolutionTime', [opt.batchname, '.pdf']);
        [dirname, ~, ~] = fileparts(pth);
        if ~exist(dirname, 'dir')
            mkdir(dirname);
        end
        saveas(gcf, pth);
        saveas(gcf, replace(pth, '.pdf', '.png'));
    end

    figure('Name',opt.title);
    for irep = 1:num_reports
        report = reports{irep};
        plot(report.ReservoirTime ./xscaling, cumsum(preparationTime(:,irep)));hold on;
    end
    xlabel(sprintf('Reservoir Time (%s)', unit));
    ylabel("Linear preparation time (s)");
    legend(names, Location="best");
    % title(opt.title);
    grid;
    hold off;
    tightfig;
    if ~isempty(opt.savefolder)
         pth = fullfile(opt.savefolder, 'linearPreparationTime', [opt.batchname, '.pdf']);
        [dirname, ~, ~] = fileparts(pth);
        if ~exist(dirname, 'dir')
            mkdir(dirname);
        end
        saveas(gcf, pth);
        saveas(gcf, replace(pth, '.pdf', '.png'));
    end

    figure('Name',opt.title);
    for irep = 1:num_reports
        report = reports{irep};
        plot(report.ReservoirTime ./xscaling, cumsum(postProcessTime(:,irep)));hold on;
    end
    xlabel(sprintf('Reservoir Time (%s)', unit));
    ylabel("Linear post process time (s)");
    legend(names, Location="best");
    % title(opt.title);
    grid;
    hold off;
    tightfig;
    if ~isempty(opt.savefolder)
        pth = fullfile(opt.savefolder, 'linearPostProcessTime', [opt.batchname, '.pdf']);
        [dirname, ~, ~] = fileparts(pth);
        if ~exist(dirname, 'dir')
            mkdir(dirname);
        end
        saveas(gcf, pth);
        saveas(gcf, replace(pth, '.pdf', '.png'));
    end
end