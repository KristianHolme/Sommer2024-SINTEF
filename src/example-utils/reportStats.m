function reportStats(reports, names, varargin)
opt = struct('plottime', true, ...
    'nonlineardetails', true, ...
    'nonlinearComparison', true, ...
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

if opt.plottime
    figure();
    for irep = 1:num_reports
        report = reports{irep};
        plot(report.ReservoirTime, cumsum(report.SimulationTime));hold on;
    end
    xlabel("Reservoir Time (s)");
    ylabel("Simulation Time (s)");
    legend(names, Location="best");
    title(opt.title);
    grid;
    hold off;
    tightfig;
    if ~isempty(opt.savefolder)
        saveas(gcf, fullfile(opt.savefolder, 'time', [opt.batchname, '.pdf']), 'pdf');
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
    figure();
    for irep = 1:num_reports
        report = reports{irep};
        plot(report.ReservoirTime, cumsum(report.Iterations));hold on;
    end
    xlabel("Reservoir Time (s)");
    ylabel("Nonlinear iterations");
    legend(names, Location="best");
    title(opt.title);
    grid;
    hold off;
    tightfig;
    if ~isempty(opt.savefolder)
        saveas(gcf, fullfile(opt.savefolder, 'nonlinearIterations', [opt.batchname, '.pdf']));
    end
end

end