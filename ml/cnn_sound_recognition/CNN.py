import torch.nn.functional as F
from torch import nn


# Define a convolutional network with 3 conv layers, pooling, and 3 fc layers with batch norm:
class CNN(nn.Module):
    def __init__(self):
        super(CNN, self).__init__()

        # Set the kernel size for the convolutional layers:
        self.f_size = 5

        # Conv. Layers using the f_size we set:
        self.conv_layer1 = nn.Conv2d(1, 7, self.f_size)
        self.conv_layer2 = nn.Conv2d(7, 17, self.f_size)
        self.conv_layer3 = nn.Conv2d(17, 35, self.f_size)

        # Pool Layer (with kernel size of 2 and stride of 2) to decrease sizes:
        self.pool = nn.MaxPool2d(2, 2)

        # FC + BatchNorm for FC (where the layer gets flattened size of 35 * 16 * 9 which is 5040):
        self.fc1 = nn.Linear(5040, 750)
        self.bn_fc1 = nn.BatchNorm1d(750)
        self.fc2 = nn.Linear(750, 100)
        self.bn_fc2 = nn.BatchNorm1d(100)
        self.fc3 = nn.Linear(100, 30)

    def forward(self, x):
        # Perform conv -> relu -> pooling for three layers:
        x = self.conv_layer1(x)
        x = F.relu(x)
        x = self.pool(x)
        x = self.conv_layer2(x)
        x = F.relu(x)
        x = self.pool(x)
        x = self.conv_layer3(x)
        x = F.relu(x)
        x = self.pool(x)

        # Flatten the input to 1d (give the batch_size and infer the other dims from it),
        # and perform fc -> batchnorm -> relu for two layers:
        batch_size = x.size(0)
        x = x.view(batch_size, -1)
        x = F.relu(self.bn_fc1(self.fc1(x)))
        x = F.relu(self.bn_fc2(self.fc2(x)))

        # Continue to third and final layer and return the softmax on the output:
        x = self.fc3(x)
        return F.log_softmax(x)