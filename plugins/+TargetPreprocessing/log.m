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

function info = log()
    info.type = DataProcessingBlockTypes.TargetPreprocessing;
    info.caption = 'natural log';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [];
    info.apply = @apply;
    info.revert = @revert;
    info.requiresNumericTarget = true;
end

function [data,params] = apply(data,params)
    target = data.target(data.cycleSelection);
    if ~isnumeric(target)
        error('Cannot take the log of non-numeric targets.');
    end
    if any(target <= 0)
        error('Cannot take the log of target values <= 0.');
    end
    d = log(target);
    data.target(data.cycleSelection) = d;
end

function numData = revert(numData,params)
    numData = exp(numData);
end