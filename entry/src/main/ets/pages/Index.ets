import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { socket } from '@kit.NetworkKit';

// Socket information interface
class SocketInfo {
  message: ArrayBuffer = new ArrayBuffer(1);
  remoteInfo: socket.SocketRemoteInfo = {} as socket.SocketRemoteInfo;
}

@Entry
@Component
struct SimpleConnectionApp {
  @State isConnected: boolean = false;
  @State statusMessage: string = 'Enter IP address';
  @State ipAddress: string = '';
  @State isConnecting: boolean = false;

  // TCP Socket variables
  private tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
  private remoteIP: string = '';
  private remotePort: number = 12345; // TARGET PORT

  aboutToDisappear(): void {
    this.closeConnection();
  }

  // Setup socket listeners
  private setupSocketListeners(): void {
    this.tcp.on('message', (value: SocketInfo) => {
      console.log("Message received");
    });

    this.tcp.on('connect', () => {
      console.log("Connection established");
      this.isConnected = true;
      this.isConnecting = false;
      this.statusMessage = 'Connected Successfully! ✓';
      promptAction.showToast({ message: 'Connected!', duration: 1000 });
    });

    this.tcp.on('close', () => {
      console.log("Connection closed");
      this.isConnected = false;
      this.isConnecting = false;
      this.statusMessage = 'Connection Lost';
    });

    this.tcp.on('error', (err: BusinessError) => {
      console.error("Socket error: " + JSON.stringify(err));
      this.isConnecting = false;
      this.statusMessage = 'Connection Error!';
      promptAction.showToast({ message: 'Connection error: ' + err.code, duration: 2000 });
    });
  }

  private connectToPC(): void {
    if (!this.ipAddress) {
      promptAction.showToast({ message: 'Please enter the IP Address', duration: 1000 });
      return;
    }

    this.remoteIP = this.ipAddress;
    this.statusMessage = 'Connecting...';

    try {
      // Bind local connection
      let localAddress: socket.NetAddress = {
        address: '0.0.0.0', // All network interfaces
        port: 0 // System will assign port automatically
      };

      this.tcp.bind(localAddress, (err: BusinessError) => {
        if (err) {
          console.error('Bind error: ' + JSON.stringify(err));
          this.statusMessage = 'Bind error';
          //return;
        }
        console.log('Bind successful');

        // Connect to remote computer
        let remoteAddress: socket.NetAddress = {
          address: this.remoteIP,
          port: this.remotePort
        };

        let connectOptions: socket.TCPConnectOptions = {
          address: remoteAddress,
          timeout: 5000
        };

        this.tcp.connect(connectOptions).then(() => {
          console.log('Connection successful');
          this.isConnected = true;
          this.statusMessage = 'Connected! ✓';
        }).catch((err: BusinessError) => {
          console.error('Connection error: ' + JSON.stringify(err));
          this.statusMessage = 'Connection Error!';
          promptAction.showToast({ message: 'Connection Error', duration: 2000 });
        });
      });

    } catch (error) {
      console.error("Socket error: " + JSON.stringify(error));
      this.statusMessage = 'Socket Error';
    }
  }

  // Close connection
  private closeConnection(): void {
    this.tcp.close().then(() => {
      console.log('Connection closed');
      this.isConnected = false;
      this.statusMessage = 'Connection Lost';
    }).catch((err: BusinessError) => {
      console.error('Close error: ' + JSON.stringify(err));
    });
  }

  private disconnect(): void {
    this.closeConnection();
    this.isConnected = false;
    this.statusMessage = 'Disconnected';
    promptAction.showToast({ message: 'Disconnected', duration: 1000 });
  }

  build() {
    Column() {

      // Status indicator
      Text(this.statusMessage)
        .fontSize(18)
        .margin({ bottom: 20 })
        .fontColor(this.isConnected ? Color.Green :
          this.isConnecting ? Color.Yellow : Color.White)

      // IP input
      TextInput({ placeholder: '192.168.1.100' })
        .width('80%')
        .height(50)
        .backgroundColor(Color.Black)
        .margin({ bottom: 15 })
        .onChange((value: string) => {
          this.ipAddress = value;
        })

      // Connect/Disconnect buttons
      if (this.isConnected) {
        Button('Disconnect')
          .width('80%')
          .height(50)
          .backgroundColor(Color.Red)
          .fontColor(Color.White)
          .onClick(() => {
            this.disconnect();
          })
      } else {
        Button(this.isConnecting ? 'Connecting...' : 'Connect')
          .width('80%')
          .height(50)
          .backgroundColor(this.isConnecting ? Color.Gray : Color.Green)
          .fontColor(Color.White)
          .onClick(() => {
            if (!this.isConnecting) {
              this.connectToPC();
            }
          })
      }

    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#1a1a1a')
  }
}