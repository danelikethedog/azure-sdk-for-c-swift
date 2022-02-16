//
//  AzureIoTSwiftViewController.swift
//  AzureIoTSwiftSample
//
//  Created by Dane Walton on 2/14/22.
//

import Foundation
import MQTT
import NIOSSL
import AzureSDKForCSwift
import CAzureSDKForCSwift

var isProvisioningConnected: Bool = false;
var isDeviceProvisioned: Bool = false;
var sendTelemetry: Bool = false;
var gOperationID: String = ""

let base: String
if CommandLine.arguments.count > 1 {
    base = CommandLine.arguments[1]
} else {
    base = "."
}

/// Dispatch Queues to Send and Receive Messages
let sem = DispatchSemaphore(value: 0)
let queue = DispatchQueue(label: "a", qos: .background)

class DemoProvisioningClient: MQTTClientDelegate {
    
    /// Azure IoT Client
    private var AzProvClient : AzureIoTDeviceProvisioningClient! = nil
    
    /// MQTT Client
    private var mqttClient: MQTTClient! = nil
    
    var delegateDispatchQueue: DispatchQueue {
        queue
    }

    public init(idScope: String, registrationID: String)
    {
        AzProvClient = AzureIoTDeviceProvisioningClient(idScope: idScope, registrationID: registrationID)

        let caCert = "\(base)/certs/baltimore.pem"
        let clientCert = "\(base)/certs/client.pem"
        let keyCert = "\(base)/certs/client-key.pem"
        let tlsConfiguration = try! TLSConfiguration.forClient(minimumTLSVersion: .tlsv11,
                                                               maximumTLSVersion: .tlsv12,
                                                               certificateVerification: .noHostnameVerification,
                                                               trustRoots: NIOSSLTrustRoots.certificates(NIOSSLCertificate.fromPEMFile(caCert)),
                                                               certificateChain: NIOSSLCertificate.fromPEMFile(clientCert).map { .certificate($0) },
                                                               privateKey: .privateKey(.init(file: keyCert, format: .pem)))
        print("Client ID: \(AzProvClient.GetDeviceProvisionigClientID())")
        print("Username: \(AzProvClient.GetDeviceProvisioningUsername())")

        mqttClient = MQTTClient(
            host: "global.azure-devices-provisioning.net",
            port: 8883,
            clientID: "\(AzProvClient.GetDeviceProvisionigClientID())",
            cleanSession: true,
            keepAlive: 30,
            username: "\(AzProvClient.GetDeviceProvisioningUsername())",
            password: "",
            tlsConfiguration: tlsConfiguration
        )
        mqttClient.tlsConfiguration = tlsConfiguration
        mqttClient.delegate = self
    }

/// Needed Functions for MQTTClientDelegate
    func mqttClient(_ client: MQTTClient, didReceive packet: MQTTPacket) {
        switch packet {
        case let packet as ConnAckPacket:
            print("[Provisioning] Connack \(packet)")
            isProvisioningConnected = true;
            
        case let packet as PublishPacket:
            print("[Provisioning] Publish Received: \(packet)");
            print("[Provisioning] Publish Topic: \(packet.topic)");
            print("[Provisioning] Publish Payload \(String(decoding: packet.payload, as: UTF8.self))");

            let provResponse: AzureIoTProvisioningRegisterResponse = AzProvClient.ParseRegistrationTopicAndPayload(topic: packet.topic, payload: String(decoding: packet.payload, as: UTF8.self))
            gOperationID = provResponse.OperationID
            print("Global Operation ID: \(gOperationID)")


            print("\(provResponse.RegistrationState.AssignedHubHostname)")
            
        case let packet as SubAckPacket:
            print("[Provisioning] Suback Received: \(packet)");

        default:
            print(packet)
        }
    }

    func mqttClient(_: MQTTClient, didChange state: ConnectionState) {
        if state == .disconnected {
            print("[Provisioning] \(state)")
            sem.signal()
        }
    }

    func mqttClient(_: MQTTClient, didCatchError error: Error) {
        print("[Provisioning] Error: \(error)")
    }

    public func connectToProvisioning() {
        mqttClient.connect()
    }
    
    public func disconnectFromProvisioning() {
        mqttClient.disconnect()
    }

    public func subscribeToAzureDeviceProvisioningFeature() {
        print("[Provisioning] Subscribing to Provisioning")
        let deviceProvisioningTopic = AzProvClient.GetDeviceProvisioningSubscribeTopic()
        print("[Provisioning] Subscribing to topic: \(deviceProvisioningTopic)")
        mqttClient.subscribe(topic: deviceProvisioningTopic, qos: QOS.1)
    }

    public func sendDeviceProvisioningRequest() {
        print("[Provisioning] Requesting to be Provisioned")
        let deviceProvisioningRequestTopic = AzProvClient.GetDeviceProvisioningRegistrationPublishTopic()
        mqttClient.publish(topic: deviceProvisioningRequestTopic, retain: false, qos: QOS.1, payload: "")
    }

    public func sendDeviceProvisioningPollingRequest(operationID: String) {
        print("[Provisioning] Quering Provisioning")
        let deviceProvisioningQueryTopic = AzProvClient.GetDeviceProvisioningQueryTopic(operationID: operationID)
        mqttClient.publish(topic: deviceProvisioningQueryTopic, retain: false, qos: QOS.1, payload: "")
    }
}

class DemoHubClient: MQTTClientDelegate {

    /// Azure IoT Client
    private var AzHubClient : AzureIoTHubClient! = nil

    /// MQTT Client
    private var mqttClient: MQTTClient! = nil
    
    var delegateDispatchQueue: DispatchQueue {
        queue
    }

    public init(iothub: String, deviceId: String)
    {
        AzHubClient = AzureIoTHubClient(iothubUrl: iothub, deviceId: deviceId)

        let caCert = "\(base)/certs/baltimore.pem"
        let clientCert = "\(base)/certs/client.pem"
        let keyCert = "\(base)/certs/client-key.pem"
        let tlsConfiguration = try! TLSConfiguration.forClient(minimumTLSVersion: .tlsv11,
                                                               maximumTLSVersion: .tlsv12,
                                                               certificateVerification: .noHostnameVerification,
                                                               trustRoots: NIOSSLTrustRoots.certificates(NIOSSLCertificate.fromPEMFile(caCert)),
                                                               certificateChain: NIOSSLCertificate.fromPEMFile(clientCert).map { .certificate($0) },
                                                               privateKey: .privateKey(.init(file: keyCert, format: .pem)))
        mqttClient = MQTTClient(
            host: "\(iothub)",
            port: 8883,
            clientID: "\(deviceId)",
            cleanSession: true,
            keepAlive: 30,
            username: "dawalton-hub.azure-devices.net/ios/?api-version=2018-06-30",
            password: "",
            tlsConfiguration: tlsConfiguration
        )
        mqttClient.tlsConfiguration = tlsConfiguration
        mqttClient.delegate = self
    }
    
/// Needed Functions for MQTTClientDelegate
    
    func mqttClient(_ client: MQTTClient, didReceive packet: MQTTPacket) {
        switch packet {
        case let packet as ConnAckPacket:
            print("[IoT Hub] Connack \(packet)")
            sendTelemetry = true;
            
        case let packet as PublishPacket:
            print("[IoT Hub] Publish Received: \(packet)");
            print("[IoT Hub] Publish Topic: \(packet.topic)");
            print("[IoT Hub] Publish Payload \(String(decoding: packet.payload, as: UTF8.self))");

        default:
            print(packet)
        }
    }

    func mqttClient(_: MQTTClient, didChange state: ConnectionState) {
        if state == .disconnected {
            sem.signal()
        }
        print(state)
    }

    func mqttClient(_: MQTTClient, didCatchError error: Error) {
        print("[IoT Hub] Error: \(error)")
    }

/// ****************** PRIVATE ******************** ///



/// ****************** PUBLIC ******************** ///

/// Sends a message to the IoT hub
    public func sendMessage() {
        let swiftString = AzHubClient.GetTelemetryPublishTopic()

        let telem_payload = "Hello iOS"
        print("[IoT Hub] Sending a message: \(telem_payload)")

        mqttClient.publish(topic: swiftString, retain: false, qos: QOS.0, payload: telem_payload)
    }

    public func connectToIoTHub() {
        mqttClient.connect()
    }

    public func disconnectFromIoTHub() {
        mqttClient.disconnect();
    }

    public func subscribeToAzureIoTHubFeatures() {
        
        // Methods
        let methodsTopic = AzHubClient.GetMethodsSubscribeTopic()
        mqttClient.subscribe(topic: methodsTopic, qos: QOS.0)
        
        // Twin Response
        let twinResponseTopic = AzHubClient.GetTwinResponseSubscribeTopic()
        mqttClient.subscribe(topic: twinResponseTopic, qos: QOS.0)

        // Twin Patch
        let twinPatchTopic = AzHubClient.GetTwinPatchSubscribeTopic()
        mqttClient.subscribe(topic: twinPatchTopic, qos: QOS.0)

    }
}

///********** Provisioning Flow **********///

private var myScopeID: String = "0ne00180E4D"
private var myRegistrationID: String = "ios"

var provisioningDemoClient = DemoProvisioningClient(idScope: myScopeID, registrationID: myRegistrationID)

provisioningDemoClient.connectToProvisioning()

while(!isProvisioningConnected) {}

provisioningDemoClient.subscribeToAzureDeviceProvisioningFeature()

provisioningDemoClient.sendDeviceProvisioningRequest()

queue.asyncAfter(deadline: .now() + 4)
{
    provisioningDemoClient.sendDeviceProvisioningPollingRequest(operationID: gOperationID)
}

while(!isDeviceProvisioned) {}

print("PROVISIONED")

provisioningDemoClient.disconnectFromProvisioning()

///********** Hub Flow **********///

//private var myDeviceId: String = "ios"
//private var myHubURL: String = "dawalton-hub.azure-devices.net"
//
//var hubDemoHubClient = DemoHubClient(iothub: myHubURL, deviceId: myDeviceId)
//
//hubDemoHubClient.connectToIoTHub()
//
//while(!sendTelemetry) {}
//
//hubDemoHubClient.subscribeToAzureIoTHubFeatures()
//
//for x in 0...5
//{
//    queue.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(x))
//    {
//        hubDemoHubClient.sendMessage()
//    }
//}
//
//queue.asyncAfter(deadline: .now() + 20) {
//    print("Ending")
//    hubDemoHubClient.disconnectFromIoTHub()
//}
//
//sem.wait()
