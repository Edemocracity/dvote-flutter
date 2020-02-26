import "./unit/hd-wallet.dart";
import "./unit/metadata.dart";
import "./net/ens.dart";
import "./net/bootnodes.dart";
import "./net/gateway.dart";
import "./integration/entity.dart";
import "./integration/voting.dart";

void main() {
  hdWallet();
  dataModels();

  ens();
  bootnodes();
  vocGateway();
  web3Gateway();
  
  entity();
  pollVoting();
}