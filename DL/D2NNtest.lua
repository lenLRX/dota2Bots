local D2NN = require("D2NN")
local testDQNpara = require("SFDQN")

-- passed
local function MatrixMulTest()

    local M1 = D2NN.Matrix:new()
    local M2 = D2NN.Matrix:new()

    M1.data = {
        [0] = 1, [1] = 2, [2] = 3,
        [3] = 4, [4] = 5, [5] = 6,
    }
    M1:SetShape(2,3)

    M2.data = {
        [0] = 1, [1] = 2, [2] = 3,
        [3] = 4, [4] = 5, [5] = 6,
        [6] = 7, [7] = 8, [8] = 9,
    }

    M2:SetShape(3,3)

    local M3 = M1 * M2
    for k,v in pairs(M3.data) do 
        --print(k,v)
    end

end

local function MatrixAddTest()
    local M1 = D2NN.Matrix:new()
    local M2 = D2NN.Matrix:new()

    M1.data = {
        [0] = 1, [1] = 2, [2] = 3,
        [3] = 4, [4] = 5, [5] = 6,
    }
    M1:SetShape(2,3)

    M2.data = {
        [0] = 1, [1] = 2, [2] = 3,
        [3] = 4, [4] = 5, [5] = 6,
    }

    M2:SetShape(2,3)

    local M3 = M1 + M2
    for k,v in pairs(M3.data) do 
        --print(k,v)
    end
end

function TestSFDQN()
    local inputdata = {1,266,-7100,-6150,1,0,0,-1781.748046875,
        -1380.0729980469,856.65606689453,592.52990722656,1024,320,
        -1656,-1512,3,3,3,1,1,0,0}
    local zero_based = {}
    
    for k,v in pairs(inputdata) do
        zero_based[k - 1] = v
    end
    
    local inputMat = D2NN.Matrix:new()
    inputMat.data = zero_based
    inputMat:SetShape(1, 22)

    local fc1 = D2NN.FCLayer:new()

    local W1 = D2NN.Matrix:new()
    W1:SetShape(22, 100)
    W1.data = testDQNpara.W1

    local B1 = D2NN.Matrix:new()
    B1:SetShape(1, 100)
    B1.data = testDQNpara.B1



    fc1:SetW(W1)
    fc1:SetB(B1)
    --fc1 out: (1,100)

    local fc2 = D2NN.FCLayer:new()

    local W2 = D2NN.Matrix:new()
    W2:SetShape(100,3)
    W2.data = testDQNpara.W2

    local B2 = D2NN.Matrix:new()
    B2:SetShape(1,3)
    B2.data = testDQNpara.B2

    fc2:SetW(W2)
    fc2:SetB(B2)

    local temp1 = fc1:ForwardProp(inputMat)
    local temp2 = fc2:ForwardProp(temp1)
end

MatrixMulTest()
MatrixAddTest()
TestSFDQN()