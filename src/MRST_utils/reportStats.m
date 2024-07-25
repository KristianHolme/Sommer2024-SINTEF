function reportStats(reports, names, varargin)
    opt = struct('plottime', true, ...
        'nonlineardetails', true, ...
        'nonlinearComparison', true, ...
        'lineardetails', true,...
        'title', '', ...
        'savefolder', '', ...
        'batchname', '', ...
        'xscaling', []);
    %TODO: add cutting stats
    
    opt = merge_options(opt, varargin{:});
    if isempty(opt.title) && ~isempty(opt.batchname)
        opt.title = opt.batchname;
    end
    opt.batchname = replace(opt.batchname, ' ', '_');
    
    num_reports = numel(reports);
    
    set(groot, 'defaultLineLineWidth', 3);
    % set(groot, 'DefaultTextFontSize', 22);
    set(0, 'DefaultAxesFontSize', 14);
    
    %Formatting
    if isa(reports{1}, 'ResultHandler')
        reports = reduceFromHandlers(reports);
    end
    
    if isempty(opt.xscaling)
        [opt.xscaling, opt.unit] = determineXScaling(reports);
    end
    
    if opt.plottime
        figure('name', opt.title);
        for irep = 1:num_reports
            report = reports{irep};
            plot(report.ReservoirTime ./ opt.xscaling, cumsum(report.SimulationTime));hold on;
        end
        xlabel(sprintf('Reservoir Time (%s)', opt.unit));
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
    
    if opt.nonlinearComparison
        figure('Name',opt.title);
        for irep = 1:num_reports
            report = reports{irep};
            plot(report.ReservoirTime ./opt.xscaling, cumsum(report.Iterations));hold on;
        end
        xlabel(sprintf('Reservoir Time (%s)', opt.unit));
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
        reports = addLinearDetails(reports);
    
        plotLinearDetails(reports, 'linearSolutionTime', 'Linear solution time (s)', names, opt)
    
        plotLinearDetails(reports, 'linearPreparationTime', 'Linear preparation time (s)', names, opt)
    
        plotLinearDetails(reports, 'linearPostProcessTime', 'Linear post process time (s)', names, opt)
    
    end
end

function reports = reduceFromHandlers(reports)
    num_report_steps = numelData(reports{1});
    num_reports = numel(reports);
    new_reports = cell(num_reports, 1);
    for ireport = 1:num_reports
        report = reports{ireport};
        new_reports{ireport} = struct();
        new_reports{ireport}.ReservoirTime = nan(num_report_steps, 1);
        new_reports{ireport}.Converged = nan(num_report_steps, 1);
        new_reports{ireport}.Iterations = nan(num_report_steps, 1);
        new_reports{ireport}.SimulationTime = nan(num_report_steps, 1);
        new_reports{ireport}.ControlstepReports = cell(num_report_steps, 1);
        for istep = 1:num_report_steps
            report_step = report{istep};
            new_reports{ireport}.ControlstepReports{istep} = report_step;
            stepreports = report_step.StepReports;
           

            new_reports{ireport}.ReservoirTime(istep) = stepreports{end}.LocalTime;
            new_reports{ireport}.Converged(istep)  = report_step.Converged;
            new_reports{ireport}.Iterations(istep) = report_step.Iterations;
            new_reports{ireport}.SimulationTime(istep) = report_step.WallTime;
        end
    end
    reports = new_reports;
end

function reports = addLinearDetails(reports)
    num_reports = numel(reports);
    for ireport = 1:num_reports
        report = reports{ireport};
        num_steps = numel(report.ReservoirTime);
        report.linearSolutionTime = zeros(num_steps, 1);
        report.linearPreparationTime = zeros(num_steps, 1);
        report.linearPostProcessTime = zeros(num_steps, 1);
        for i_step = 1:num_steps
            controlStepReport = reports{ireport}.ControlstepReports{i_step};
            stepReports = controlStepReport.StepReports;
            for i_stepReport = 1:numel(stepReports)
                nonlinearReport = stepReports{i_stepReport}.NonlinearReport;
                for i_nlRep = 1:(numel(nonlinearReport)-1)
                    report.linearSolutionTime(i_step) = report.linearSolutionTime(i_step)...
                        + nonlinearReport{i_nlRep}.LinearSolver.LinearSolutionTime;

                    report.linearPreparationTime(i_step) = report.linearPreparationTime(i_step)...
                        + nonlinearReport{i_nlRep}.LinearSolver.PreparationTime;

                    report.linearPostProcessTime(i_step) = report.linearPostProcessTime(i_step)...
                        + nonlinearReport{i_nlRep}.LinearSolver.PostProcessTime;
                end
            end
        end
        reports{ireport} = report;
    end
end

function plotLinearDetails(reports, field, ytxt, names, opt)
    figure('Name',opt.title);
    num_reports = numel(reports);
    for irep = 1:num_reports
        report = reports{irep};
        plot(report.ReservoirTime ./ opt.xscaling, cumsum(report.(field)));hold on;
    end
    xlabel(sprintf('Reservoir Time (%s)', opt.unit));
    ylabel(ytxt);
    legend(names, Location="best");
    grid;
    hold off;
    tightfig;
    if ~isempty(opt.savefolder)
        pth = fullfile(opt.savefolder, field, [opt.batchname, '.pdf']);
        [dirname, ~, ~] = fileparts(pth);
        if ~exist(dirname, 'dir')
            mkdir(dirname);
        end
        saveas(gcf, pth);
        saveas(gcf, replace(pth, '.pdf', '.png'));
    end
end

function [xscaling, unit] = determineXScaling(reports)
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
end