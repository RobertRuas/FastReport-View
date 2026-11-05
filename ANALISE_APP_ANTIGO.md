# Análise do FastReport antigo — base para o novo app minimalista

> Fonte: https://github.com/RobertRuas/FastReport (clonado para análise em `/private/tmp/.../scratchpad/old-fastreport-src`, não faz parte deste repo).
> Objetivo: extrair só os dois recursos que o novo app vai ter — (1) visualizar/organizar fotos arrastando dentro da grade, (2) arrastar uma foto da nossa app para outra app externa (Finder, Word, etc.) — sem herdar o resto (mapas, triagem por teclado, projetos, Sparkle já temos, etc.).

## O que o app antigo faz (contexto, não vamos replicar tudo)

App nativo macOS que organiza fotos de obra **no disco** (Finder é a fonte da verdade, sem biblioteca própria). Fluxo: Projeto → Mapa (grupos/slots como T1–T24) → Inbox → Triagem (1 foto por vez, teclado) → Revisão (grade por pasta, reordenar) → Entrega (arrastar JPEGs para o relatório noutra app). Stack: SwiftUI + AppKit, Xcode project (não SPM), Swift 6.

**Não vamos portar**: mapas/slots, assistente de projeto, triagem por teclado, watcher de pasta, Sparkle (o novo app já tem o seu próprio em `Sources/App/UpdaterController.swift`), i18n.

## Recurso 1 — Reordenar fotos arrastando (drag dentro da grade)

Arquivos de referência no app antigo:
- `FastReport/Domain/LiveReorderLayout.swift` — lógica pura, sem UI. Três funções:
  - `targetIndex(from:translationX:cellWidth:count:)` — calcula o índice de destino a partir do deslocamento do drag, arredondando pela largura da célula.
  - `movingItem(in:from:to:)` — move um item de um array (remove + insert).
  - `neighborOffset(index:dragIndex:targetIndex:cellWidth:)` — calcula quanto cada vizinho deve deslizar (±cellWidth) para abrir espaço visualmente enquanto o drag acontece.
- `FastReport/Features/Review/LiveReorderStrip.swift` — a view SwiftUI que usa a lógica acima. Usa `DragGesture(minimumDistance: 6)`, guarda `origin` (snapshot da ordem antes do drag), `dragStartIndex`, `translationX` em `@State`, aplica `.offset`/`.scaleEffect`/`.shadow`/`.zIndex` no item arrastado e `.animation(.interactiveSpring)` nos vizinhos. No fim do drag (`onEnded`), chama `onCommitMove(start, target)` que o chamador usa para persistir a nova ordem.
- Persistência da ordem no disco: `FastReport/Services/FileOrganizer.swift` → `reorder(urls:moving:to:project:slot:)` e `renumber(...)` — renomeia os ficheiros sequencialmente (move para nome temporário, depois para o nome final numerado) para a ordem no disco refletir a ordem visual. Isso é específico do sistema de nomes do app antigo (`Inspecao1_T10_1.jpeg`); o novo app não tem esse padrão de nomenclatura, então a persistência da ordem precisa ser decidida à parte (ver "Pontos de atenção" abaixo).

**Ponto de atenção importante para a nossa arquitetura**: `LiveReorderStrip` usa `@State` para o estado transitório do drag (`origin`, `dragStartIndex`, `translationX`). O `AI_PROJECT_MAP.md` do nosso projeto diz explicitamente que **`@State`, `@Binding` e `@Environment` não estão disponíveis** (plugin SwiftUIMacros ausente nas Command Line Tools) — só `@Observable` + `Binding(get:set:)` manual. Isso significa que **não podemos copiar `LiveReorderStrip` como está**. A lógica pura de `LiveReorderLayout.swift` é 100% portável (é só Foundation, sem SwiftUI). A view precisa reimplementar o estado de drag usando uma classe `@Observable` (um pequeno view-model de reorder) em vez de `@State` local.

## Recurso 2 — Arrastar foto da nossa app para fora (outra app externa)

Arquivo de referência: `FastReport/Features/Delivery/ExternalFileDragOverlay.swift`.

Esse recurso **não usa `@State`** — é implementado em AppKit puro dentro de um `NSViewRepresentable`, então é diretamente portável para a nossa arquitetura. Mecanismo:
- `ExternalFileDragView: NSView, NSDraggingSource` — detecta `mouseDown`/`mouseDragged` (com um limiar de 4pt para diferenciar clique de drag) e inicia `beginDraggingSession(with:event:source:)`.
- `ReportPhotoPasteboardWriter: NSObject, NSPasteboardWriting` — escreve no pasteboard em 3 formatos: `.fileURL`, `NSFilenamesPboardType` (legado, para apps antigas que só leem esse tipo) e o tipo UTI da imagem (`UTType.jpeg.identifier` com os bytes do ficheiro). Isso maximiza compatibilidade com apps externas (Word, Pages, Finder, etc.).
- `draggingSession(_:sourceOperationMaskFor:)` retorna `.copy` só quando o contexto é `.outsideApplication` (dentro da nossa app não permite soltar).
- `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()` ao redor do drag — necessário se o ficheiro vier de uma pasta aberta via sandbox/bookmark; a view clica com `onPreview()` (clique simples sem arrastar) e tem um menu de contexto opcional (`onToggle`, marcar/desmarcar) que o novo app provavelmente não precisa no início.

Esse componente pode ser copiado quase 1:1, simplificado (sem o menu de marcar/desmarcar, que é específico do fluxo de "Entrega" do app antigo).

## Modelo de dados minimalista necessário

O app antigo tem `DiskPhoto` (id estável via inode, url, slotId, fileName) em `FastReport/Domain/DiskPhoto.swift`. Para o novo app só precisamos de algo como `id` (estável, baseado em inode ou caminho) + `url` — sem `slotId` (não há slots/mapas).

## Etapas de implementação propostas (sem fugir da estrutura atual do projeto)

Seguindo os padrões existentes em `AI_PROJECT_MAP.md` (Models/, Views/, um tipo por ficheiro, `@Observable` + `Binding(get:set:)`, sem comentários no código):

1. **Modelo de foto + leitura de pasta** — `Sources/Models/Photo.swift` (id estável, url) + serviço simples (`Sources/Services/PhotoFolderLoader.swift` ou similar) que lista imagens de uma pasta escolhida pelo utilizador (NSOpenPanel ou drag de pasta). Sem watcher de ficheiros por agora — só carregar quando o utilizador escolhe a pasta.
2. **Grade de fotos (visualização)** — nova view em `Sources/Views/Home/` (ou uma nova secção) que mostra thumbnails numa grade/strip, adaptando `ThumbnailView.swift` do app antigo (carregamento de imagem + cache simples). Sem zoom/crop/rotação do app antigo — só mostrar.
3. **Reordenar arrastando (drag interno)** — portar `LiveReorderLayout.swift` tal como está (lógica pura). Criar um pequeno `@Observable` (ex: `Sources/Models/PhotoReorderState.swift`) para substituir o `@State` de `LiveReorderStrip`, guardando `draggedPhotoID`, `translationX`, snapshot da ordem. A view usa esse objeto via `Binding(get:set:)`/referência direta à classe observável.
4. **Persistir a nova ordem** — decidir o mecanismo (índice guardado em memória/JSON ao lado da pasta, já que não há o padrão de nomenclatura `Inspecao1_T10_1` do app antigo). Não renomear ficheiros a não ser que o utilizador peça explicitamente — é mais seguro para um app minimalista que só organiza visualmente.
5. **Arrastar para fora (drag externo)** — portar `ExternalFileDragOverlay.swift` quase sem alterações (remover o menu de marcar/desmarcar). Aplicar como overlay/gesto em cada thumbnail da grade.
6. **Polimento** — preview ao clicar (reaproveitando `onPreview`), feedback visual do item sendo arrastado (shadow/scale, já replicável com `@Observable`).

Cada etapa deve ser implementada e validada isoladamente antes de avançar para a próxima. Depois de cada etapa que criar/mover/remover ficheiros, atualizar `AI_PROJECT_MAP.md` conforme a regra do `CLAUDE.md`.
