# This is a simple implementation of a TCP server, which receives requests and sends files or JPGs accordingly (from a networking course)

import socket, threading, os.path

def main():
    # Create a new socket and listen on all addresses with the port 12345:
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_ip = '0.0.0.0'
    server_port = 12345
    server.bind((server_ip, server_port))
    server.listen(5)

    # current_dir = os.path.dirname(os.path.realpath(__file__))

    fileExistsMsg = "HTTP/1.1 200 OK\nConnection: close\n\n"
    fileNotExistsMsg = "HTTP/1.1 404 Not Found\nConnection: close\n\n"
    redirectMsg = "HTTP/1.1 301 Moved Permanently\nConnection: close\nLocation: /result.html\n\n"

    while True:

        # Read a message from the client:
        client_socket, client_address = server.accept()
        print 'Connection from: ', client_address

        # Read the first batch:
        request = client_socket.recv(2048)
        print "Read a batch!"

        # If the request is empty, close the socket and continue. This will
        # sometimes happen because Chrome pre-fetches it's pages (sends web requests
        # while the user is still typing in the address bar), or because it sends an extra request
        # for the favicon. So we ignore it:
        if not request:
            client_socket.close()
            continue

        lines = request.splitlines()
        for line in lines:
            print line
        path = lines[0].split("GET", 1)[1].split("HTTP", 1)[0].strip()

        while "\r\n\r\n" not in request:
            print "Keeps on reading"
            request = client_socket.recv(2048)
            lines = request.splitlines()
            for line in lines:
                print line

        if path == "/":
            path = "/index.html"

        if path == "/redirect":
            client_socket.send(redirectMsg)
            client_socket.close()
            continue

        is_jpg = False
        if path.endswith(".jpg"):
            is_jpg = True

        path = "files" + path
        if os.path.exists(path):
            print path + " Exists!"
            client_socket.send(fileExistsMsg)
            if is_jpg:
                sendJPG(path, client_socket)
            else:
                sendFile(path, client_socket)
            client_socket.close()
            continue
        else:
            print path + " Not here!"
            client_socket.send(fileNotExistsMsg)
            client_socket.close()
            continue


def sendFile(path, client_socket):
    print "Sending regular file.."
    with open(path, 'r') as file:
        for line in file:
            client_socket.send(line)
    file.close()


def sendJPG(path, client_socket):
    print "Sending binary JPG.."
    with open(path, 'rb') as file:
        binary_file = file.read()
        client_socket.send(binary_file)
    file.close()

if __name__ == "__main__":
    main()
