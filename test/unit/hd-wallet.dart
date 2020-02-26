import 'package:flutter_test/flutter_test.dart';
import 'package:dvote/dvote.dart';

void hdWallet() {
  test('Generate random mnemonics', () {
    final mnemonicRegExp = new RegExp(r"^[a-z]+( [a-z]+)+$");

    final wallet1 = EthereumWallet.random();
    expect(mnemonicRegExp.hasMatch(wallet1.mnemonic), true);

    final wallet2 = EthereumWallet.random();
    expect(mnemonicRegExp.hasMatch(wallet2.mnemonic), true);
    expect(wallet1.mnemonic != wallet2.mnemonic, true);

    final wallet3 = EthereumWallet.random();
    expect(mnemonicRegExp.hasMatch(wallet3.mnemonic), true);
    expect(wallet1.mnemonic != wallet3.mnemonic, true);
    expect(wallet2.mnemonic != wallet3.mnemonic, true);

    final wallet4 = EthereumWallet.random();
    expect(mnemonicRegExp.hasMatch(wallet4.mnemonic), true);
    expect(wallet1.mnemonic != wallet4.mnemonic, true);
    expect(wallet2.mnemonic != wallet4.mnemonic, true);
    expect(wallet3.mnemonic != wallet4.mnemonic, true);
  });

  test("Create a wallet for a given mnemonic", () {
    EthereumWallet wallet = EthereumWallet.fromMnemonic(
        'coral imitate swim axis note super success public poem frown verify then');
    expect(wallet.privateKey,
        '0x975a999c921f77c1812833d903799cdb7780b07809eb67070ac2598f45e9fb3f');
    expect(wallet.publicKey,
        '0x046fbd249af1bf365abd8d0cfc390c87ff32a997746c53dceab3794e2913d4cb26e055c8177faab65b404ea24754d8f56ef5df909a39d99ee0e7ca291a11556b37');
    expect(wallet.address, '0x6aaa00b7c22021f96b09bb52cb9135f0cb865c5d');

    wallet = EthereumWallet.fromMnemonic(
        'almost slush girl resource piece meadow cable fancy jar barely mother exhibit');
    expect(wallet.privateKey,
        '0x32fa4a65b9cb770235a8f0af497536035a459a98179c2c667972be279fbd1a1a');
    expect(wallet.publicKey,
        '0x0425eb0aac23fe343e7ac5c8a792898a4f1d55b3150f3609cde6b7ada2dff029a89430669dd7f39ffe72eb9b8335fef52fd70863d123ba0015e90cbf68b58385eb');
    expect(wallet.address, '0xf0492a8dc9c84e6c5b66e10d0ec1a46a96ff74d3');

    wallet = EthereumWallet.fromMnemonic(
        'civil very heart sock decade library moment permit retreat unhappy clown infant');
    expect(wallet.privateKey,
        '0x1b3711c03353ecbbf7b686127e30d6a37a296ed797793498ef24c04504ca5048');
    expect(wallet.publicKey, '0x04ae5f2ecb63c4b9c71e1b396c8206720c02bddceb01da7c9f590aa028f110c035fa54045f6361fa0c6b5914a33e0d6f2f435818f0268ec8196062d1521ea8451a');
    expect(wallet.address, '0x9612bd0deb9129536267d154d672a7f1281eb468');
  });

  test("Compute the private key for a given mnemonic and derivation path", () {
    // index 0
    EthereumWallet wallet = EthereumWallet.fromMnemonic(
        'civil very heart sock decade library moment permit retreat unhappy clown infant',
        hdPath: "m/44'/60'/0'/0/0");
    expect(wallet.privateKey,
        '0x1b3711c03353ecbbf7b686127e30d6a37a296ed797793498ef24c04504ca5048');
    expect(wallet.publicKey,
        '0x04ae5f2ecb63c4b9c71e1b396c8206720c02bddceb01da7c9f590aa028f110c035fa54045f6361fa0c6b5914a33e0d6f2f435818f0268ec8196062d1521ea8451a');
    expect(wallet.address, '0x9612bd0deb9129536267d154d672a7f1281eb468');

    // index 1
    wallet = EthereumWallet.fromMnemonic(
        'civil very heart sock decade library moment permit retreat unhappy clown infant',
        hdPath: "m/44'/60'/0'/0/1");
    expect(wallet.privateKey,
        '0x2b8642b869998d77243669463b68058299260349eba6c893d892d4b74eae95d4');
    expect(wallet.publicKey, '0x04d8b869ceb2d90c2ab0b0eecd2f4215f42cb40a82e7de854ca14e85a1a84e00a45e1c37334666acb08b62b19f42c18524d9d5952fb43054363350820f5190f17d');
    expect(wallet.address, '0x67b5615fdc5c65afce9b97bd217804f1db04bc1b');

    // index 2
    wallet = EthereumWallet.fromMnemonic(
        'civil very heart sock decade library moment permit retreat unhappy clown infant',
        hdPath: "m/44'/60'/0'/0/2");
    expect(wallet.privateKey,
        '0x562870cd36727fdca458ada4c2a34e0170b7b4cc4d3dc3b60cba3582bf8c3167');
    expect(wallet.publicKey, '0x04887f399e99ce751f82f73a9a88ab015db74b40f707534f54a807fa6e10982cbfaffe93414466b347b83cd43bc0d1a147443576446b49d0e3d6db24f37fe02567');
    expect(wallet.address, '0x0887fb27273a36b2a641841bf9b47470d5c0e420');
  });
}