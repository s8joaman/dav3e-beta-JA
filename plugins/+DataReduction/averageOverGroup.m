% This file is part of DAVE, a MATLAB toolbox for data evaluation.
% Copyright (C) 2018-2019 Saarland University, Author: Manuel Bastuck
% Website/Contact: www.lmt.uni-saarland.de, info@lmt.uni-saarland.de
% 
% The author thanks Tobias Baur, Tizian Schneider, and Jannis Morsch
% for their contributions.
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU Affero General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Affero General Public License for more details.
% 
% You should have received a copy of the GNU Affero General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>. 

function info = averageOverGroup()
    info.type = DataProcessingBlockTypes.DataReduction;
    info.caption = 'group average';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','grouping', 'value','', 'enum',{''})...
        ];
    info.apply = @apply;
    info.updateParameters = @updateParameters;
end

function [data,params] = apply(data,params)
    data.reduceData(@reduceFun, data.getGroupingByName(params.grouping));
end

function updateParameters(params,project)
    for i = 1:numel(params)
        if params(i).shortCaption == string('grouping')
            params(i).enum = cellstr(project.groupings.getCaption());
            if isempty(params(i).value)
                params(i).value = params(i).enum{1};
            end
        end
    end
end

function [newData,newGrouping,newTarget,newOffsets] = reduceFun(data,grouping,target,offsets,varargin)
    newData = [];
    newGrouping = grouping(false);
    newTarget = target(false);
    newOffsets = [];
    averagingGrouping = varargin{1}; % grouping to average over
    cats = categories(averagingGrouping); 
    for cidx = 1:numel(cats)
        idx = averagingGrouping==cats{cidx};
        newData = [newData; mean(data(idx,:),1)];
        newGrouping = [newGrouping; categoricalAverage(grouping(idx,:))];
        newTarget = [newTarget; categoricalAverage(target(idx,:))];
    end
    newOffsets = (1:size(newTarget,1))';  % offsets will be undefined after averaging
end

function out = categoricalAverage(inVec)
    if isnumeric(inVec)
        out = mean(inVec,1);
    else
        out = categorical.empty;
        for i = 1:size(inVec,2)
            col = removecats(inVec(:,i));
            cats = categories(col);
            [~,idx] = max(histcounts(col));
            if isempty(idx)
                out(:,i) = categorical(nan);
            else
                out(:,i) = categorical(cats(idx));
            end
        end
    end
end