# This is a sample Python script.

# Press ⌃R to execute it or replace it with your code.
# Press Double ⇧ to search everywhere for classes, files, tool windows, actions, and settings.

import torch
from torch.utils.data import Dataset
from torch import nn


def print_hi(name):
    # Use a breakpoint in the code line below to debug your script.
    print(f'Hi, {name}')  # Press ⌘F8 to toggle the breakpoint.

# import data
# class MyDataSet(Dataset):
#     def __init__(self):


class MyModel(nn.Module):
    def __init__(self):
        super(MyModel, self).__init__()
        self.net = nn.Sequential(
            nn.Linear(10, 32),
            nn.Sigmoid(),
            nn.Linear(32, 1)
        )

    def forward(self, x):
        return self.net(x)


#optimize


# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    # hah = torch.cuda.is_available()


    x = torch.tensor([[0.5, 0.], [-0.5, 0.5]], requires_grad=True)
    z = x.pow(2).sum()
    print(z.backward())
    print(x.grad)

    layer = torch.nn.Linear(32,64)
    torch.nn.MSELoss
    print(layer.weight.shape)

    print_hi('PyCharm')

# See PyCharm help at https://www.jetbrains.com/help/pycharm/
