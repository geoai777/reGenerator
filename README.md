# reGenerator
Automates generation of classes from .proto files for gRPC Dart (Can be used with other languages)

## requirements
pre installation requirements can be found [here](https://grpc.io/docs/languages/dart/quickstart/) and [here](https://protobuf.dev/getting-started/cpptutorial/#compiling-your-protocol-buffers)

`/!\` WARINING! Once more, checklist:
- [protoc](https://github.com/protocolbuffers/protobuf/releases)
- dart plugin for protoc (when you run reGenerator it will check if there is plugin available)

## Usage
- create folder (it can be anywhere like `<project>/gRPC/auth`
- place `regen.ps1` in this folder
- create `.proto` file (something like `auth.proto`) See more [here](https://protobuf.dev/getting-started/darttutorial/)
- open terminal and run `.\regen.ps1` - if file left to default values it will create folder `gen` and place genrerated files there.


## Disclaimer
the software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and oninfringement. in no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.
