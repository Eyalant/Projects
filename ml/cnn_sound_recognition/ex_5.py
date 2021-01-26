import torch.nn.functional as F
from gcommand_loader import GCommandLoader
import torch
from torch import optim
import CNN


def main():
    # Determine the device to work on:
    gpu_available = torch.cuda.is_available()
    print("Will CUDA calcs be used: " + str(gpu_available))
    device = torch.device("cuda" if gpu_available else "cpu")

    # Get the datasets through the gcommand_loader:
    train_dataset, valid_dataset, test_dataset = fetch_datasets()

    # Get the loaders using the datasets:
    train_loader, valid_loader, test_loader = fetch_loaders(train_dataset, valid_dataset, test_dataset)

    # Get the classes mapping from the training dictionary:
    classes_dict = train_loader.dataset.classes

    # Get the wav names in test folder:
    wav_names = create_test_wav_names(test_dataset)

    # Define the model, optimizer and lr to use:
    model = CNN.CNN().to(device)
    optimizer = optim.Adam(model.parameters(), lr=0.001)

    # Train the model on the training loader and output preds from the test loader
    # to test_y:
    epochs = 5
    for epoch in range(epochs):
        train(epoch, model, optimizer, train_loader, device)

        # Checking loss & acc. on the validation set:
        test(model, valid_loader, device)
    test_to_file(model, test_loader, wav_names, classes_dict, device)


def fetch_loaders(train_dataset, valid_dataset, test_dataset):

    # Define the training loader (with shuffled data and batch of 100):
    train_loader = torch.utils.data.DataLoader(
            train_dataset, batch_size=100, shuffle=True,
            pin_memory=True, sampler=None)

    # Define the validation loader (without shuffled data, to simulate test):
    valid_loader = torch.utils.data.DataLoader(
            valid_dataset, batch_size=100, shuffle=False,
            pin_memory=True, sampler=None)

    # Define the test loader (without shuffled data and a batch of one):
    test_loader = torch.utils.data.DataLoader(
            test_dataset, shuffle=False,
            pin_memory=True, sampler=None)

    return train_loader, valid_loader, test_loader


def fetch_datasets():
    train_dataset = GCommandLoader('./train')
    valid_dataset = GCommandLoader('./valid')
    test_dataset = GCommandLoader('./test')

    # Checking train ds:
    # for _, (data, _) in enumerate(train_dataset):
    #    for vec in data:
    #        print("row:")
    #        print(vec)

    return train_dataset, valid_dataset, test_dataset


def create_test_wav_names(test_dataset):
    # Create a list of the wav names and add every item in the test dataset to it:
    test_wav_names_list = []
    for wav in test_dataset.spects:
        # Split the string to get the file name (after .../test\\test\\):
        test_wav_names_list.append(wav[0].split('./test\\test\\')[1])
    return test_wav_names_list


def test_to_file(model, test_loader, wav_names, classes_dict, device):
    # Create the predictions list and switch to eval. mode:
    predictions = []
    model.eval()

    # Iterate on the test loader and add the predictions for each data to the list:
    for idx, (data, _) in enumerate(test_loader):
        data = data.to(device)
        output = model(data)
        pred = output.max(1, keepdim=True)[1]
        # print(str(pred))
        # print(wav_names[idx] + ', ' + classes_dict[int(pred)])
        predictions.append(pred)

    # Write these predictions to test_y:
    print("Now writing to test_y\n")
    with open('test_y', 'w') as file:
        for idx, pred in enumerate(predictions):
            file.write(wav_names[idx] + ',' + classes_dict[int(pred)] + '\n')
        # file.write(wav_names[predictions[-1]] + ',' + classes_dict[int(predictions[-1])])
    print("Finished\n")


def train(epoch, model, optimizer, train_loader, device):
    # Train the model using the train loader (same as ex4):
    print("\nEpoch " + str(epoch) + "\n")
    model.train()
    for batch_idx, (data, labels) in enumerate(train_loader):
        data = data.to(device)
        labels = labels.to(device)
        print("Training Batch #" + str(batch_idx) + " out of " + str((len(train_loader.dataset) / 100) - 1))
        optimizer.zero_grad()
        output = model(data)
        loss = F.nll_loss(output, labels)
        loss.backward()
        optimizer.step()


def test(model, loader_to_test, device):
    # Test the model using the loader to test (same as ex4):
    model.eval()
    test_loss = 0
    correct = 0
    for data, target in loader_to_test:
        data = data.to(device)
        target = target.to(device)
        output = model(data)
        test_loss += F.nll_loss(output, target, size_average=False).item() # sum up batch loss
        pred = output.max(1, keepdim=True)[1] # get the index of the max log-probability
        # print(pred)
        correct += pred.eq(target.view_as(pred)).cpu().sum()
    test_loss /= len(loader_to_test.dataset)
    test_acc = 100. * correct / len(loader_to_test.dataset)
    print('\nTest set: Average loss: {:.4f}, Accuracy: {}/{} ({:.0f}%)\n'.format(
    test_loss, correct, len(loader_to_test.dataset), test_acc))


if __name__ == "__main__":
    main()
