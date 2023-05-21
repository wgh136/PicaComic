import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelectDownloadChapter extends StatefulWidget {
  const SelectDownloadChapter(this.eps, this.finishSelect, {Key? key}) : super(key: key);
  final List<String> eps;
  final void Function(List<int>) finishSelect;

  @override
  State<SelectDownloadChapter> createState() => _SelectDownloadChapterState();
}

class _SelectDownloadChapterState extends State<SelectDownloadChapter> {
  List<int> selected = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
            child: Text("下载漫画".tr, style: const TextStyle(fontSize: 22),),
          ),
          Expanded(child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
              childAspectRatio: 4,
            ),
            itemBuilder: (BuildContext context, int i) {
              return Padding(padding: const EdgeInsets.all(4),child: InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: AnimatedContainer(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    color: selected.contains(i)?Theme.of(context).colorScheme.primaryContainer:Theme.of(context).colorScheme.surfaceVariant,
                  ),
                  duration: const Duration(milliseconds: 200),

                  child: Row(
                    children: [
                      const SizedBox(width: 16,),
                      Text(widget.eps[i]),
                      const Spacer(),
                      if(selected.contains(i))
                        const Icon(Icons.done),
                      const SizedBox(width: 16,),
                    ],
                  ),
                ),
                onTap: (){
                  setState(() {
                    if(selected.contains(i)){
                      selected.remove(i);
                    } else {
                      selected.add(i);
                    }
                  });
                },
              ),);
            },
            itemCount: widget.eps.length,
          ),),
          SizedBox(
            height: 50,
            child: Row(
              children: [
                const SizedBox(width: 16,),
                Expanded(child: FilledButton.tonal(onPressed: (){
                  widget.finishSelect(List<int>.generate(widget.eps.length, (index) => index));
                }, child: Text("下载全部".tr)),),
                const SizedBox(width: 16,),
                Expanded(child: FilledButton.tonal(onPressed: (){
                  widget.finishSelect(selected);
                }, child: Text("下载选择".tr)),),
                const SizedBox(width: 16,),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom,
          )
        ],
      ),
    );
  }
}
