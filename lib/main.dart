import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // gerado pelo comando: flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Batalha de Ideias',
      debugShowCheckedModeBanner: false,
      home: TelaPrincipal(),
    );
  }
}

class TelaPrincipal extends StatelessWidget {
  // controladores dos campos de texto
  final tituloController = TextEditingController();
  final descricaoController = TextEditingController();
  final autorController = TextEditingController();

  // cadastrar nova ideia (votos sempre comeca com 0)
  void salvarIdeia() {
    FirebaseFirestore.instance.collection('ideias').add({
      'titulo': tituloController.text,
      'descricao': descricaoController.text,
      'autor': autorController.text,
      'votos': 0,
    });
    tituloController.clear();
    descricaoController.clear();
    autorController.clear();
  }

  // abre a janelinha para cadastrar
  void abrirCadastro(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Nova ideia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloController,
                decoration: InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: descricaoController,
                decoration: InputDecoration(labelText: 'Descrição'),
              ),
              TextField(
                controller: autorController,
                decoration: InputDecoration(labelText: 'Autor'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              child: Text('Salvar'),
              onPressed: () {
                salvarIdeia();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Batalha de Ideias')),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          abrirCadastro(context);
        },
      ),
      // StreamBuilder = fica escutando o Firebase em tempo real
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('ideias').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Deu erro!'));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var ideias = snapshot.data!.docs;

          if (ideias.isEmpty) {
            return Center(child: Text('Nenhuma ideia ainda. Cadastre uma!'));
          }

          // descobrir a ideia mais votada
          var maisVotada = ideias[0];
          for (var ideia in ideias) {
            if (ideia['votos'] > maisVotada['votos']) {
              maisVotada = ideia;
            }
          }

          return ListView(
            padding: EdgeInsets.all(10),
            children: [
              // ranking
              Card(
                color: Colors.amber[200],
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Text(
                        '🏆 IDEIA MAIS VOTADA',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        maisVotada['titulo'],
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text('${maisVotada['votos']} votos'),
                    ],
                  ),
                ),
              ),

              // lista de todas as ideias
              for (var ideia in ideias)
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ideia['titulo'],
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text('Autor: ${ideia['autor']}'),
                        SizedBox(height: 8),
                        Text(ideia['descricao']),
                        SizedBox(height: 8),
                        Text('❤️ ${ideia['votos']} votos'),
                        Row(
                          children: [
                            ElevatedButton(
                              child: Text('VOTAR'),
                              onPressed: () {
                                // soma 1 no voto direto no Firebase
                                ideia.reference.update({
                                  'votos': FieldValue.increment(1),
                                });
                              },
                            ),
                            SizedBox(width: 10),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                // apaga o documento do Firebase
                                ideia.reference.delete();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
