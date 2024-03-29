classdef tswls < handle
    
    properties
        imdata
        stidata
    end
    
    properties
        IndTrace
        AveTrace
        stadata
        plotdata
    end
    
    methods
        
        function obj = tswls (d1, d2)
            
            obj.imdata(:,1)  = d1;
            obj.stidata      = d2;
        end
    end
    
    methods
        
        % Boxcar filter
        function bcfilt (obj, num)
            
            obj.imdata(:,2) = moving_average(obj.imdata(:,1),num);
        end
        
        % Extract individual traces and average traces
        function extTraces (obj,varargin)
            
            % set baseline value
            % 3 choices:
            % 1, an absolute value for all traces, e.g., fitted/ manually set value;
            % 2, average value from some points for all traces, e.g., 1000:1500;
            % 3, average value form some points before stimulus, e.g., average points 1s
            %    before stimulus onset as baseline for each trace.
            % when baseline is noisy && changing, e.g., too much spontaneous (after
            % drugs), choose 1 or 2; when baseline is changing but not noisy, e.g.,
            % long time recording, choose 3.
            
            %
            p = inputParser;
            p.addRequired ('framePeriod');
            p.addRequired ('traceLength');
            p.addOptional ('preStmLength', 1);
            p.addParameter('fixedValue',[]);
            p.addParameter('average1',[]);
            p.addParameter('average2',[]);
            p.parse(varargin{:});
            
            framePeriod = p.Results.framePeriod;
            traceLength = p.Results.traceLength;
            preStmLength= p.Results.preStmLength;
            fixedValue  = p.Results.fixedValue;
            average1    = p.Results.average1;
            average2    = p.Results.average2;
            
           
             % extract time and stimulus trace for full data
            frameNumber           = length (obj.imdata(:,1));
            stTrace               = obj.stidata.data(:,3);
            obj.plotdata.raw(:,1) = framePeriod * (1:1:frameNumber);
            obj.plotdata.raw(:,2) = stTrace;
            
             % extract traces Using stdata
            nsti           = length (obj.stidata.trailInfo);
            preStmLength   = round(preStmLength / framePeriod);
            traceLength    = round(traceLength / framePeriod);
            intervalLength = round(1 / framePeriod);
            stStartFrame   = zeros(nsti);
            
            for i = 1:nsti
                stStartFrame(i)            = obj.stidata.trailInfo(i).startFrameN;
                traceStartFrame            = stStartFrame(i) - preStmLength;
                traceEndFrame              = traceStartFrame + traceLength - 1;
                obj.IndTrace(:,i)          = obj.imdata(traceStartFrame : traceEndFrame,2);
                obj.plotdata.time(:,i)     = framePeriod * ( (traceLength + intervalLength) * (i-1) +1 : 1 : (traceLength + intervalLength) * i - intervalLength);                                              
                obj.plotdata.st(:,i)       = stTrace(traceStartFrame:traceEndFrame);
                
            end
            
            % deltaF / F
            if ~isnan(fixedValue)
                obj.IndTrace    = (obj.IndTrace - fixedValue) / fixedValue * 100;
                % deltaF / F for whole trace, for visualization of
                % spontaneous activity or retinal waves/ added 11/28/2017 
                obj.imdata(:,3) = (obj.imdata(:,2) - fixedValue) / fixedValue * 100;
            elseif ~isnan(average1)
                baselineStartFrame = stStartFrame - round(average1 / framePeriod);
                for i = 1:nsti
                    baselineValue  = mean(obj.imdata(baselineStartFrame(i):stStartFrame(i),2));
                    obj.IndTrace(:,i) = (obj.IndTrace(:,i) -baselineValue) / baselineValue * 100;
                end
            else
                if length(average2) == 1 % single number indicates fixed distance
                    baselineStartFrame = stStartFrame (1) - round(average2 / framePeriod);
                    baselineValue      = mean(obj.imdata(baselineStartFrame:stStartFrame(1),2));
                    
                else
                    baselineValue      = mean(obj.imdata(average2, 2));
                end
                obj.IndTrace           = (obj.IndTrace - baselineValue) / baselineValue * 100;
                % deltaF / F for whole trace, for visualization of
                % spontaneous activity or retinal waves/ added 11/28/2017 
                obj.imdata(:,3)        = (obj.imdata(:,2) - baselineValue) / baselineValue * 100;
            end
            
            % average traces for each stimulus pattern
            npat = length (obj.stidata.patternInfo);
            for i = 1:npat
                traceN = obj.stidata.patternInfo(i).trailN;
                if size (traceN,1) == 1  % no drug
                obj.AveTrace(:,i) = mean(obj.IndTrace(:,traceN),2);
                else
                    obj.AveTrace(:,1,i) = mean(obj.IndTrace(:,traceN(1,:)),2);
                    obj.AveTrace(:,2,i) = mean(obj.IndTrace(:,traceN(2,:)),2);
                end
            end
            
            
        end
        
        % make statistics
        function getStatistics (obj,preStmLength,stLength,framePeriod,onLength,offLength)
            
            preStmLength = round(preStmLength / framePeriod);
            onLength     = round(onLength     / framePeriod);
            stLength     = round(stLength     / framePeriod);
            offLength    = round(offLength    / framePeriod);
            
            % on/off frames to get on/off peak
            onFrame      = preStmLength + 1 : preStmLength + onLength;
            offFrame     = preStmLength + stLength + 1 : preStmLength + stLength + offLength;
            
            % for individual
            nsti           = length (obj.stidata.trailInfo);
            % get on/off peak from average traces
            obj.stadata.peakAveTrace(1,:) = max (obj.AveTrace(onFrame,:));
            obj.stadata.peakAveTrace(2,:) = max (obj.AveTrace(offFrame,:));
            
            % get on/off areas
            onFrame1 = preStmLength + 1 : preStmLength + stLength;
            offFrame1= preStmLength + stLength + 1 : length(obj.AveTrace);
            
            obj.stadata.area(1,:) = trapz(onFrame1,obj.AveTrace(onFrame1,:));
            obj.stadata.area(2,:) = trapz(offFrame1,obj.AveTrace(offFrame1,:));
            % get on/off asymmetric index
%             obj.stadata.asyInd            = (obj.stadata.peakAveTrace(1,:) - obj.stadata.peakAveTrace(2,:))...
%                                             ./ (obj.stadata.peakAveTrace(1,:) + obj.stadata.peakAveTrace(2,:));
            
        end
        
        % add method to analyze DS
        
        % show traces in different modes
        function showTraces (obj,varargin)
            
            option = varargin{1};
            haxes  = varargin{2};
            c      = varargin{3};
            
            axes(haxes);
            switch option
%                 case 'Raw'
%                     t           = obj.plotdata.raw(:,1);
%                     stTrace     = obj.plotdata.raw(:,2);
%                     plot(t,obj.imdata(:,2),'Color',c,'LineWidth',1);hold on;
%                     plot(t,stTrace,'k','LineWidth',1);
                    % The following command can not work. Why?
%                     plot(t,obj.imdata,'Color',c,t,stTrace,'k','LineWidth',1);
                case 'Raw'  % Raw data with delta F/F
                    t           = obj.plotdata.raw(:,1);
                    stTrace     = obj.plotdata.raw(:,2);
                    baseline    = zeros (1, length (obj.imdata(:,3)));
                    plot(t,obj.imdata(:,3),'Color',c,'LineWidth',1);hold on;
                    plot(t,baseline,'--k','LineWidth',1);
                    plot(t,stTrace,'k','LineWidth',1);
                case 'TrailByTrail'
                    nsti        = length (obj.stidata.trailInfo);
                    baseline    = zeros (1, length (obj.IndTrace));
                    for i = 1:nsti
                        data    = obj.IndTrace (:,i);
                        t       = obj.plotdata.time(:,i);
                        stTrace = obj.plotdata.st(:,i);
                        plot(t,data,'Color',c,'LineWidth',1);hold on;
                        plot(t,stTrace,'k','LineWidth',1);hold on;
                        plot(t,baseline,'--k','LineWidth',1);hold on;
                        
                    end
                case 'Average'
                    npat = length (obj.stidata.patternInfo);
                    baseline    = zeros (1, length (obj.IndTrace));
                    % Test whether drug experiments performed
                    if size (obj.stidata.patternInfo(1).trailN, 1) == 1 % no drug
                    for i = 1:npat
                        nTrace = length (obj.stidata.patternInfo(i).trailN);
                        t       = obj.plotdata.time(:,i);
                        stTrace = obj.plotdata.st(:,obj.stidata.patternInfo(i).trailN(1));
                        for j = 1:nTrace
                            data    = obj.IndTrace (:,obj.stidata.patternInfo(i).trailN(j));
                            plot(t,data,'Color',[0.827 0.827 0.827],'LineWidth',1);
                            hold on;
                        end
                        avedata = obj.AveTrace (:,i);
                        plot(t,avedata,'Color',c,'LineWidth',1);hold on;
                        plot(t,stTrace,'k','LineWidth',1);hold on;
                        plot(t,baseline,'--k','LineWidth',1);
                    end
                    else
                        for i = 1:npat
                        nTracec = length (obj.stidata.patternInfo(i).trailN(1,:));
                        nTraced = length (obj.stidata.patternInfo(i).trailN(2,:));
                        t       = obj.plotdata.time(:,i);
                        stTrace = obj.plotdata.st(:,i);
                        for j = 1:nTracec
                            data    = obj.IndTrace (:,obj.stidata.patternInfo(i).trailN(1,j));
                            plot(t,data,'Color',[0.827 0.827 0.827],'LineWidth',1);
                            hold on;
                        end
                        
                        for j = 1:nTraced
                            data    = obj.IndTrace (:,obj.stidata.patternInfo(i).trailN(2,j));
                            plot(t,data,'Color',[0.827 0.827 0.827],'LineWidth',1);
                            hold on;
                        end
                        avedatac = obj.AveTrace (:,1,i);
                        avedatad = obj.AveTrace (:,2,i);
                        plot(t,avedatac,'Color','k','LineWidth',1);hold on;
                        plot(t,avedatad,'Color','r','LineWidth',1);hold on;
                        plot(t,stTrace,'k','LineWidth',1);hold on;
                        plot(t,baseline,'--k','LineWidth',1);
                        end
                    end
                    
            end
            
            
        end
        
    end
    
    
end