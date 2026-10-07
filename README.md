# SimplifyKit (`sk`)

Bộ lệnh cho Claude Code giúp bạn đi từ **một User Story trên Azure DevOps** đến code đã xong, mà không phải viết lại yêu cầu lần thứ hai.

Bạn đưa nó mã work item — hoặc, với việc không có work item, gọi `/sk:propose` kèm yêu cầu viết trực tiếp. Nó đọc acceptance criteria từ board, viết ra bản đặc tả và danh sách việc cần làm, bạn xem lại, rồi nó làm. Những gì nó viết ra đều là file markdown nằm trong repo — review được trên PR như mọi thay đổi khác.

## Khái niệm cốt lõi

SimplifyKit tách rời hai thứ: một **bản đặc tả sống lâu dài**, ghi hệ thống hôm nay phải làm gì; và một **thay đổi đang đề xuất**, chỉ ghi phần chênh lệch mà một User Story mới thêm vào. Tới khi bạn duyệt xong, thay đổi mới gộp vào đặc tả. Mô hình specs/changes này gần với OpenSpec — khác ở chỗ đầu vào chính là một work item Azure DevOps thật; yêu cầu viết trực tiếp là cửa phụ, chỉ mở khi bạn gọi rõ lệnh:

```mermaid
flowchart LR
    C["sk/changes/&lt;id&gt;/<br/>thay đổi đang đề xuất<br/>proposal + spec delta + tasks"] -->|"/sk:archive<br/>merge"| S["sk/specs/&lt;nhóm&gt;/spec.md<br/>đặc tả đang hiệu lực<br/>tích luỹ qua nhiều User Story"]
```

**Spec** là nguồn sự thật, viết bằng **Requirement** — một cam kết ("hệ thống SHALL ..."). SHALL là từ khoá cố định nghĩa là "phải", viết hoa theo lối đặc tả kỹ thuật kiểu RFC/OpenSpec: câu nào có SHALL là chắc chắn một cam kết kiểm chứng được, không lẫn với câu mô tả suông — nên công cụ, và cả Claude khi đọc lại spec sau này, cứ nhìn từ khoá là nhận ra Requirement, không phải đoán ý. Mỗi Requirement có một hoặc nhiều **Scenario**: một ví dụ quan sát được, viết theo cặp WHEN/THEN — WHEN nêu chuyện gì xảy ra, THEN nêu điều quan sát được sau đó (thêm GIVEN khi có tiền đề, AND khi có thêm hệ quả). Ví dụ:

> Requirement: hệ thống SHALL cho phép lọc sản phẩm theo màu.
> Scenario: **WHEN** người dùng chọn màu đỏ, **THEN** chỉ hiện sản phẩm màu đỏ.

Requirement không có Scenario là một ước muốn; Scenario không ai kiểm được là văn xuôi. Ví dụ đầy đủ nằm ở mục "Các file trong `sk/` nghĩa là gì" bên dưới. Quy tắc đầy đủ nằm ở [`plugins/sk/reference/conventions.md`](plugins/sk/reference/conventions.md) — gồm: mỗi Requirement chỉ một câu SHALL, Scenario phải quan sát được, và GIVEN chỉ xuất hiện khi có tiền đề đáng kể.

**Change** không sửa spec trực tiếp. Nó viết một **delta** — khối `## ADDED Requirements` / `## MODIFIED Requirements` / `## REMOVED Requirements`, mô tả *chênh lệch* so với spec hiện tại, không phải toàn bộ hệ thống. `/sk:archive` áp delta đó: `ADDED` thêm Requirement mới, `MODIFIED` **thay nguyên khối** Requirement cùng tên (nên phải chép lại cả Scenario không đổi — chi tiết ở "Có một quy tắc bạn cần nhớ" bên dưới), `REMOVED` xoá hẳn.

| Thuật ngữ | Nghĩa |
|---|---|
| **Spec** | Đặc tả đang hiệu lực, tích luỹ qua nhiều User Story đã archive |
| **Change** | Một thay đổi đang đề xuất — `proposal.md` + spec delta + `tasks.md`, sống riêng cho tới khi archive |
| **Requirement** | Một cam kết: hệ thống SHALL làm gì |
| **Scenario** | Một ví dụ quan sát được của Requirement |
| **Delta** | Phần spec trong một change, khai bằng ADDED/MODIFIED/REMOVED — chênh lệch, không phải bản đầy đủ |
| **Nhóm** (capability) | Một lát hành vi người đọc nhận ra ngay là một thứ, ví dụ `field-selector` — không phải một layer hay một sprint |
| **Proposal** | `proposal.md` — tóm tắt yêu cầu, giả định đã đặt ra, và Gaps (AC chưa đủ rõ để dịch) |
| **Archive** | Merge delta vào spec, ghi lại ADR và thuật ngữ nếu có, rồi chuyển change sang `sk/changes/archive/<id>/` |
| **ADR** | Một quyết định thiết kế khó đảo ngược, ghi lại lúc archive (`sk/adr/`) để lý do không mất theo `design.md` |
| **Glossary** | `sk/context.md` — thuật ngữ riêng của dự án, chỉ những từ mà một change thực sự định nghĩa |

## Vì sao thiết kế như vậy

AC đã nằm sẵn trên Azure DevOps. Việc bắt người dùng gõ lại nó vào một prompt là tạo thêm một bản sao — hai bản ghi cho cùng một yêu cầu, sớm muộn cũng lệch nhau. Nên `/sk:propose` chỉ dịch AC có sẵn thành Requirement/Scenario kiểm chứng được, chưa rõ thì dừng lại hỏi (mục Gaps) chứ không bịa cho đủ.

Cũng vì vậy `/sk:propose` **hỏi trước khi quyết định**: cách tách AC thành requirement, capability nào sở hữu việc này, comment nào ghi đè mô tả — mỗi câu kèm đáp án nó đề xuất, để bạn chỉ cần gật hoặc sửa. Những thứ nó vẫn tự tra được (nội dung work item, spec hiện có) thì nó không hỏi.

Từ đó ra cách chia bước: intent (ADO) → spec (`spec.md`) → kế hoạch (`tasks.md`) → code → review trên PR, mỗi bước để lại một file cho bước sau đọc. `/sk:propose` và `/sk:continue` không đụng code dù bạn bảo "làm luôn đi", và mỗi lần chỉ tạo một artifact để bạn duyệt từng bước, vì sửa một file markdown đỡ tốn công sức hơn sửa code đã viết sai; mọi artifact review được ngay trên PR, bạn không phải đoán xem bên trong đã xảy ra chuyện gì.

Vì `sk/specs/` là bản đặc tả chung, gom qua hàng chục User Story, nên khi `archive` chạy, nó thay nguyên cả khối Requirement bằng bản trong delta, không vá từng mảnh.

Cách `archive` nhận diện đúng Requirement cần thay là so tên. Vì vậy nếu delta viết thiếu một Scenario, Scenario đó biến mất khỏi đặc tả chung mà không có gì báo lỗi (chi tiết ở mục "Có một quy tắc bạn cần nhớ" bên dưới).

Phần dưới đi vào từng bước bằng một ví dụ thật.

## Cài đặt

Chạy một lần trên máy bạn:

```
/plugin marketplace add thanhsang95/Simplify-Kit
/plugin install sk@simplify
```

Kiểm tra plugin đã bật:

```bash
claude plugin list          # tìm dòng: sk@simplify … Status: enabled
```

Plugin không tự cập nhật ngầm — muốn lấy version mới thì tự chạy:

```
/plugin update sk@simplify
```

Đang dùng bản 0.1.x? Cập nhật xong, xem mục [Nâng cấp từ bản cũ](#nâng-cấp-từ-bản-cũ-01x) — repo đã có `sk/` cần chạy lại `/sk:init` một lần.

Không có bước xem trước: chạy xong là nhận thẳng bản mới, không có gate cho xem skill nào đổi trước khi áp dụng. Nếu lệnh trên không nhận, cập nhật lại marketplace (`/plugin marketplace add thanhsang95/Simplify-Kit`) rồi cài lại (`/plugin install sk@simplify`).

Nếu thấy `disabled` thì bật lên — lúc đang tắt, các lệnh `/sk:*` sẽ không xuất hiện:

```bash
claude plugin enable sk@simplify
```

### Azure DevOps: chuẩn bị trước khi chạy `/sk:init`

`/sk:init` đọc org/project mặc định qua Azure CLI, còn `/sk:propose` sau này dùng token do CLI cấp để đọc work item qua REST. Vì vậy hãy cài CLI và đăng nhập từ trước — đừng đợi tới lúc lỗi mới làm:

1. Cài [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) nếu máy chưa có.
2. Cài extension `azure-devops` — lệnh `az devops` thuộc extension này, không có sẵn trong `az` gốc:
   ```bash
   az extension add --name azure-devops
   ```
3. Đăng nhập:
   ```bash
   az login
   ```
   Kiểm mình đã login chưa bằng một lệnh cho kết quả quan sát được, cùng nhịp với `claude plugin list` ở trên:
   ```bash
   az account show          # đã login: JSON có "user": { "name": ... }. Chưa login: báo lỗi
   ```

Sau đó, mỗi repo làm một lần:

```
/sk:init
```

Lệnh này tạo thư mục `sk/` và ghi `sk/config.yaml` — file mô tả dự án cho Claude: stack dùng gì, lệnh build/test là gì, tài liệu nào nên đọc trước khi làm việc. Xem qua file đó một lượt ngay lúc này: nó là thứ Claude đọc mỗi lần chạy `/sk:*` sau này, nên nếu có chỗ nào tả sai dự án, sửa bây giờ đỡ tốn công sức hơn nhiều so với sửa sau khi đã có vài change dựa trên nó.

Lệnh này cũng đụng tới một file bạn đã có sẵn: nó **append** một đoạn giới thiệu `sk/` vào `./CLAUDE.md`, hoặc vào `./.claude/CLAUDE.md` nếu `./CLAUDE.md` không tồn tại nhưng file kia có; nếu repo chưa có file nào trong hai file đó, nó **tạo mới `./CLAUDE.md`**. Nội dung cũ không bị viết đè hay sắp lại, chỉ nối thêm ở cuối. `/sk:apply` sau này cũng ghi ngoài `sk/` — nhưng đó là code bạn đã yêu cầu, ở bước bạn đang chờ sẵn. `/sk:init` thì khác: nó sửa một file bạn đã sở hữu từ trước mà không ai yêu cầu riêng, nên đáng nói ngay ở đây. `git diff CLAUDE.md` sau khi chạy `/sk:init` sẽ cho thấy đúng đoạn đó.

Nó cũng **append một dòng vào `.gitignore`** (tạo file nếu chưa có): `sk/changes/archive/`, vì change đã xong được ghi lại bằng spec, ADR và glossary nên bản sao đã archive chỉ là nhiễu. Các change đang mở dưới `sk/changes/<id>/` thì vẫn được commit.

Để lấy `ado.orgUrl` và `ado.project`, `/sk:init` chạy `az devops configure --list` — lệnh này chỉ trả về gì đó nếu máy bạn từng đặt defaults bằng `az devops configure --defaults organization=<org-url> project=<project>`. Nếu chưa từng đặt, hoặc lệnh thất bại, `/sk:init` **cố ý để trống** hai trường này trong `sk/config.yaml` kèm comment nhắc điền, rồi báo lại cho bạn biết — đây là hành vi bình thường, không phải hỏng.

Điền tay thì lấy `orgUrl` **đầy đủ**, đừng dựng lại từ tên ngắn: org kiểu cũ vẫn nằm ở `https://<org>.visualstudio.com/`, còn `https://dev.azure.com/<org>` là một endpoint khác — dùng nhầm dạng nào thì việc đọc work item sau này fail.

```yaml
ado:
  orgUrl: "https://contoso.visualstudio.com/"   # copy nguyên từ az devops configure --list
  project: "MyProject"
```

## Một vòng làm việc

Giả sử bạn được giao User Story **12345**.

### 1. Lập kế hoạch — `/sk:propose`

```
/sk:propose AB#12345
```

Nó đọc work item, **hỏi bạn một lượt câu hỏi** về cách đọc nó (mỗi câu đánh số `G1`, `G2`… kèm đáp án nó đề xuất), rồi sau khi bạn xác nhận mới ghi ra **một file**: `proposal.md`. Chưa có spec, chưa có tasks.

Lượt hỏi đầu tiên luôn có, kể cả khi AC đã gom nhóm rõ — lúc đó nó chỉ là một lần xác nhận ngắn. Chạy tự động, không ai trả lời được, thì nó ghi đáp án đề xuất và đánh dấu từng mục trong `## Assumptions` là `unconfirmed`, để người duyệt biết mục nào chưa ai xem.

```
sk/changes/us-12345-<tên-ngắn>/
  proposal.md            tóm tắt yêu cầu, AC nằm ở đâu, cách nó đọc AC, và những chỗ AC chưa đủ rõ
```

`<tên-ngắn>` không phải thứ bạn tự đặt — Claude tự rút gọn từ tiêu đề work item (ví dụ US 12345 "Add product attributes to field selector" → `us-12345-field-selector`), và nói tên đó ra trong câu trả lời khi kết thúc. Nếu bỏ lỡ, cứ mở `sk/changes/` mà xem tên thư mục.

**Bước này không sửa một dòng code nào**, và cũng không tự viết spec. Kể cả khi bạn bảo "làm luôn đi", nó vẫn chỉ ghi `proposal.md` rồi dừng — lý do nằm ở mục "Vì sao thiết kế như vậy" phía trên. Dừng ở đây là chủ ý: đây là chỗ bạn kiểm tra nó **hiểu AC thế nào** trước khi có spec nào được dựng lên trên cách hiểu đó.

Work item không có AC thì `proposal.md` ghi `AC source: none yet` cùng mục Gaps, và `/sk:continue` sẽ không viết spec cho tới khi giải quyết xong.

#### Việc không có work item — yêu cầu trực tiếp

Refactor, tech debt, spike, hay việc chưa kịp lên board:

```
/sk:propose Xuất báo cáo tồn kho ra CSV. Khi quá 10.000 dòng thì gửi file qua email thay vì tải trực tiếp.
```

Phần còn lại giống hệt luồng work item: hỏi `G1`, `G2`…, ghi `proposal.md` rồi dừng. Khác biệt:

- Change-id là `req-<tên-ngắn>` (ví dụ `req-inventory-csv-export`), không có số
- `proposal.md` chép **nguyên văn** yêu cầu vào `## Request` — không có board nào giữ hộ, nên đây là bản duy nhất
- **AC phải là của bạn.** Tiêu chí bạn viết trong yêu cầu được dùng luôn (`AC source: user, in conversation`). Yêu cầu không có tiêu chí ("làm cho tải báo cáo nhanh hơn") thì nó đề xuất AC dưới dạng câu hỏi, và chỉ dùng sau khi bạn xác nhận. Chạy tự động không ai xác nhận thì ghi `AC source: none yet`, và `/sk:continue` sẽ không viết spec — khác với các quyết định khác, AC do model tự soạn không bao giờ được ghi `unconfirmed` rồi đi tiếp
- Chỉ kích hoạt khi bạn **gọi rõ** `/sk:propose` (hoặc nói "sk propose …"). Mô tả một tính năng trong lúc trò chuyện bình thường sẽ không tạo change nào

### 2. Đọc `proposal.md`, rồi đi tiếp từng bước — `/sk:continue`

Mở `proposal.md`: nó nhóm AC thành các requirement như thế nào? Có AC nào bị bỏ sót, hoặc nhóm sai? Sửa thẳng vào file, hoặc nói cho nó sửa. Xong thì:

```
/sk:continue us-12345-<tên-ngắn>
```

Mỗi lần gọi, nó tạo **đúng một artifact tiếp theo** rồi dừng, theo thứ tự:

1. `specs/<nhóm>/spec.md` — đặc tả: hệ thống phải làm gì, viết theo cặp Requirement/Scenario. Bước này đọc lại work item để chắc không dựng trên chữ đã cũ
2. `design.md` — chỉ khi phải chọn giữa các phương án kỹ thuật. Không cần thì nó ghi `## Design: Skipped` vào `proposal.md` và tính là xong bước
3. `tasks.md` — danh sách việc cần làm, chia theo hạng mục, chưa việc nào được tick

Không có lệnh trạng thái nào — nó nhìn file nào đã có trên đĩa để biết đang ở bước nào. Sau mỗi bước, đọc file vừa tạo như thể bạn là người nghiệm thu:

- Có scenario nào sai ý không?
- Có yêu cầu nào trong US mà đặc tả bỏ sót không?
- Có scenario nào *không* có trong US — tức nó tự nghĩ ra?

Xem luôn mục **Gaps** và **Open questions** trong `proposal.md`: Gaps là chỗ AC chưa đủ rõ để dịch thành scenario; Open questions là chỗ scenario đã viết nhưng một con số hay quy tắc chưa ai chốt. Cả hai đều không phải chỗ nó tự bịa cho đủ.

### 3. Làm — `/sk:apply`

```
/sk:apply us-12345-<tên-ngắn>
```

Nó đọc `tasks.md`, làm từng task theo thứ tự, và với mỗi task: sửa hoặc tạo file code thật trong repo — nằm ngoài `sk/`, ở đúng chỗ code của dự án — để khớp với spec, rồi tick `- [x]` vào đúng dòng task đó. Vì vậy `tasks.md` vừa là kế hoạch vừa là nhật ký tiến độ: mở lên là biết đang xong tới đâu, không cần hỏi lại.

Nó sẽ **dừng lại hỏi** nếu task mơ hồ, nếu phát hiện lỗ hổng trong kế hoạch, hoặc nếu việc cần làm vượt quá những gì đặc tả mô tả — thay vì tự quyết rồi làm tắt.

Xong thì chạy build/test của dự án như bình thường, hoặc để `/sk:verify` chạy lệnh test ghi trong `sk/config.yaml` ở bước sau.

### 4. Kiểm — `/sk:verify`

```
/sk:verify us-12345-<tên-ngắn>
```

Trước khi archive, lệnh này so code với chính những gì change đã hứa và **chỉ báo cáo, không sửa gì**: không đổi code, không đụng artifact, không tick hay bỏ tick task. Nó kiểm ba chiều:

- **Completeness** — mọi task đã tick chưa, và mỗi requirement có code thật đứng sau không. Tick rồi mà không có code vẫn bị báo, vì ô đã tick chỉ là một lời khẳng định
- **Correctness** — mỗi scenario có được code xử lý và có test chưa; diff có làm thêm thứ gì mà không requirement nào yêu cầu; còn open question nào khiến `/sk:archive` sẽ dừng
- **Coherence** — code có theo `design.md` và các `rules` trong `sk/config.yaml` không

Mỗi vấn đề được xếp mức CRITICAL (phải sửa trước khi archive), WARNING hoặc SUGGESTION, kèm `file:dòng` và một việc cụ thể cần làm. Có shell thì nó so trên diff từ merge-base với nhánh chính và chạy lệnh test ghi trong `sk/config.yaml`. Không có shell thì nó đọc code theo tasks và delta, và nói rõ đã bỏ qua phần nào.

Bước này nên chạy, nhưng không bắt buộc: `/sk:archive` không đòi phải verify trước, và vẫn tự chạy các kiểm tra merge của nó.

### 5. Đóng lại — `/sk:archive`

```
/sk:archive us-12345-<tên-ngắn>
```

Ba việc xảy ra theo thứ tự: mỗi requirement trong `sk/changes/<id>/specs/` **thay nguyên khối** requirement cùng tên trong `sk/specs/<nhóm>/spec.md` — bản đặc tả sống, gộp yêu cầu của toàn hệ thống qua nhiều story; rồi lưu lại những gì việc merge một mình sẽ làm mất (xem dưới); cuối cùng cả thư mục `sk/changes/<id>/` được chuyển sang `sk/changes/archive/<id>/`.

**`sk/changes/archive/` không được commit** (`/sk:init` thêm nó vào `.gitignore`). Nên sau khi archive, thứ git giữ lại của change chỉ còn spec đã merge — còn lý do của một quyết định thiết kế (nằm trong `design.md`) và các thuật ngữ change đó đưa vào sẽ biến mất cùng thư mục. Vì vậy trước khi chuyển, `/sk:archive` soạn sẵn và **hỏi bạn xác nhận** hai thứ:

- **ADR** (`sk/adr/NNNN-<tên>.md`) từ `design.md` — chỉ khi change có `design.md` *và* quyết định đó khó đảo ngược, sẽ gây ngạc nhiên nếu thiếu ngữ cảnh, và là kết quả của một sự đánh đổi thật. Không có `design.md` thì không có ADR
- **Thuật ngữ** trong `sk/context.md` — chỉ những từ delta/proposal thực sự định nghĩa và riêng cho dự án này

Chạy không có ai trả lời (ví dụ tự động hoá) thì archive vẫn merge và chuyển như thường nhưng **bỏ qua hai thứ này** và in bản nháp ra để bạn áp dụng sau: ADR và glossary là bản ghi dài hạn duy nhất còn lại, không nên chứa lý do chưa ai đọc.

Change đã archive từ trước khi có bước này thì chạy `/sk:archive backfill` một lần để ghi bù (xem "Nâng cấp từ bản cũ").

Bước này quan trọng hơn vẻ ngoài: `sk/specs/` là thứ lần sau Claude đọc để biết **hệ thống hiện đang phải thoả những gì**. Không archive thì lần sau nó làm việc trong tình trạng mất trí nhớ — không biết story này đã từng tồn tại, chứ đừng nói tới việc nó đã đổi những gì.

## Nâng cấp từ bản cũ (0.1.x)

Chạy lại `/sk:init` trong repo đã có `sk/`. Lệnh này **không bao giờ ghi đè** `config.yaml`; nó chỉ kiểm tra workspace có gì khác bản hiện tại và đề xuất các thay đổi kiểu *append*: thêm `sk/changes/archive/` vào `.gitignore`, đánh dấu `## Design` "Skipped" cho các change đã lên kế hoạch từ trước khi có `/sk:continue`, và thêm dòng `**AC source:** none yet` cho change đang chờ AC. Nó hiện toàn bộ kế hoạch và hỏi bạn **một lần**; chạy không có người trả lời thì chỉ áp dụng ba việc trên.

Hai việc nó **chỉ báo, không tự làm**: các change đã archive vẫn đang bị git theo dõi (in ra lệnh `git rm -r --cached sk/changes/archive` — chạy nó làm đồng đội mất các thư mục đó khi pull, nên là quyết định của cả nhóm), và các change đã archive chưa có ADR/glossary: chạy **một lần** `/sk:archive backfill` — nó đọc mọi change đã archive, gộp và bỏ trùng thuật ngữ thành một bản nháp `sk/context.md`, soạn ADR cho từng change có `design.md` xứng đáng, và hỏi bạn **một lần** (thuật ngữ hai change định nghĩa khác nhau sẽ được hỏi lại, không tự chọn). Làm việc này **trước khi** bỏ theo dõi. Cũng có thể chạy `/sk:archive <id>` với một change đã archive để chỉ soạn bản ghi cho riêng nó.

## Các file trong `sk/` nghĩa là gì

| Đường dẫn | Nội dung |
|---|---|
| `sk/config.yaml` | Mô tả dự án cho Claude: stack, lệnh build/test, tài liệu nên đọc, thông tin ADO |
| `sk/specs/<nhóm>/spec.md` | **Đặc tả đang hiệu lực** — hệ thống hôm nay phải làm gì. Tích luỹ qua nhiều story |
| `sk/changes/<id>/` | Một thay đổi đang làm dở — **có commit**, để đồng đội review và để kit thấy việc chưa archive của người khác |
| `sk/changes/archive/<id>/` | Thay đổi đã xong — **chỉ nằm trên máy**, bị `.gitignore` |
| `sk/adr/NNNN-<tên>.md` | Quyết định thiết kế đã chốt, ghi lại lúc archive |
| `sk/context.md` | Bảng thuật ngữ riêng của dự án, cập nhật lúc archive |

Một spec delta chia làm ba khối tuỳ change đang thêm, sửa, hay bỏ yêu cầu nào: `## ADDED Requirements`, `## MODIFIED Requirements`, `## REMOVED Requirements` — chỉ viết khối nào cần dùng. Trong mỗi khối, mỗi yêu cầu viết thế này — trích nguyên văn từ một `spec.md` do `/sk:continue` sinh ra:

```markdown
## ADDED Requirements

### Requirement: Field selector offers system-defined product attributes

The "Select a field" dropdown in the Add field rule panel SHALL offer the system-defined
product attributes available in the catalog portal in addition to the standard product fields.

#### Scenario: Attributes are selectable alongside standard fields

- **WHEN** an administrator opens the "Select a field" dropdown in the Add field rule panel
- **THEN** every system-defined product attribute available in the catalog portal SHALL be
  offered for selection
- **AND** the standard product fields SHALL still be offered
```

Đọc từ trên xuống: *Requirement* là cam kết, *Scenario* là điều kiểm chứng được. Đặc tả luôn viết bằng tiếng Anh — kể cả khi work item và phần trao đổi với Claude là tiếng Việt — vì template mà skill dùng ([`plugins/sk/templates/spec-delta.md`](plugins/sk/templates/spec-delta.md)) viết SHALL/WHEN/THEN bằng tiếng Anh và skill theo đúng khuôn đó.

Sau khi `/sk:apply` chạy xong một task, `tasks.md` trông thế này — cũng trích từ output thật:

```markdown
## 1. Attribute source

- [x] 1.1 Add `src/attribute-fields.ts` exporting `listAttributeFields()`, returning system-defined attributes with `key` and `label`
```

Task 1.1 khớp đúng với những gì đã xảy ra trong repo ở lần chạy đó: file `src/attribute-fields.ts` được tạo mới.

`/sk:archive` thì thay nguyên khối, không nối thêm. Một requirement trong `sk/specs/` trước khi archive có 2 scenario; change đang được archive mang một bản delta 3 scenario cho cùng requirement đó; sau archive, requirement trong `sk/specs/` có đúng 3 scenario — bản 2 scenario cũ không còn dấu vết. Cơ chế thay-nguyên-khối này là lý do có quy tắc riêng ở mục "Có một quy tắc bạn cần nhớ" bên dưới.

## Khi nào nó sẽ hỏi bạn

Kit được thiết kế để **dừng lại hỏi** thay vì đoán. Vài tình huống hay gặp:

**"Bạn muốn đọc work item này thế nào?"**
Trước khi ghi `proposal.md`, `/sk:propose` hỏi cách tách AC, capability và các comment ghi đè, kèm đáp án đề xuất. Đây là hành vi bình thường, không phải lỗi — và là chỗ rẻ nhất để chỉnh, trước khi có spec nào dựng lên trên cách đọc đó.

**"Work item này không có acceptance criteria."**
Khoảng 1/5 số User Story rơi vào đây. Nó sẽ đưa ra những gì lấy được (tiêu đề, mô tả, comment) rồi hỏi tiêu chí nghiệm thu. Nó **không** tự bịa ra đặc tả từ một ô trống — nếu bạn thấy nó làm vậy, đó là lỗi, báo lại.

**"Tiêu chí này tôi chưa chuyển thành hành vi quan sát được."**
Một AC viết chung chung quá thì nó đưa vào mục Gaps và hỏi, thay vì nặn thành scenario cho đủ số.

**"Hai thay đổi đang mâu thuẫn nhau."**
Khi `/sk:archive` thấy hai change cùng sửa một yêu cầu theo hai hướng, nó dừng và đưa cả hai phía cho bạn quyết. Nó không tự hoà giải, vì không có cách nào biết cái nào mới hơn.

**"Hãy archive change kia trước."**
Không phải lỗi — chỉ là thứ tự. Change này dựa trên yêu cầu mà change kia tạo ra.

## Có một quy tắc bạn cần nhớ

Nếu bạn **tự tay sửa** file spec delta trong `sk/changes/<id>/specs/`, và phần đó nằm dưới `## MODIFIED Requirements`:

> Phải giữ lại **toàn bộ** requirement, kể cả những scenario bạn không đụng tới.

Vì lúc archive, requirement cũ trong `sk/specs/` bị thay nguyên khối bằng bản trong delta — đúng như ví dụ 2-scenario-thành-3-scenario ở trên. Xoá bớt scenario ở đây đồng nghĩa xoá chúng khỏi đặc tả chung — mà không có cảnh báo nào, vì tên vẫn khớp.

Cách an toàn: copy nguyên requirement từ `sk/specs/` sang rồi sửa trên bản copy. (`/sk:archive` có kiểm nếu số scenario giảm đi, nhưng đừng dựa vào đó.)

## Những gì kit cố ý không làm

- **Không sửa code ở bước `propose` hay `continue`, và không viết hai artifact trong một lần gọi** — kể cả khi bạn yêu cầu trong cùng câu lệnh
- **Không ghi gì lên Azure DevOps** — không comment, không tạo Task, không đổi state. Cập nhật board vẫn là việc của bạn
- **Không tự nhận mô tả tự do** — một yêu cầu không có work item chỉ thành change khi bạn gọi rõ `/sk:propose <yêu cầu>`, và AC của nó phải do bạn viết hoặc xác nhận
- **Không nhận số trần** — `12345` là mơ hồ, vì trong repo này số trần đã mang nghĩa mã PR. Gõ `AB#12345`

## Gỡ rối

| Hiện tượng | Xử lý |
|---|---|
| Không thấy lệnh `/sk:*` nào | Plugin đang tắt: `claude plugin list` rồi `claude plugin enable sk@simplify` |
| `/sk:propose` bảo chạy `/sk:init` trước | Repo chưa có `sk/`. Chạy `/sk:init`. Kit cố ý không tự tạo `sk/` |
| Nó hỏi lại thay vì viết đặc tả | Work item thiếu acceptance criteria, hoặc yêu cầu trực tiếp chưa có tiêu chí bạn viết/xác nhận. Đây là hành vi đúng |
| `proposal.md` của change `req-…` ghi `AC source: none yet` | Yêu cầu không có tiêu chí và chưa ai xác nhận AC nó đề xuất (thường do chạy tự động). Chạy lại `/sk:propose req-…` và xác nhận các tiêu chí trong mục Gaps |
| Nó báo lỗi khi đọc work item | Kiểm `az login`, và `ado.orgUrl` trong `sk/config.yaml` có đúng URL đầy đủ không |
| `/sk:propose` hỏi mà không ghi file | Đúng thiết kế: nó chờ bạn xác nhận. Không có ai trả lời được (script) thì nói rõ trong yêu cầu, nó sẽ ghi đáp án đề xuất và đánh dấu `unconfirmed` |
| `git status` hiện `sk/changes/archive/` là untracked | Repo chưa ignore nó: chạy lại `/sk:init` (nó sẽ đề xuất thêm dòng vào `.gitignore`) |
| `/sk:archive` dừng giữa chừng | Nó phát hiện xung đột và đang chờ bạn quyết. Đọc thông báo — nó nói rõ requirement nào |

## Muốn sửa chính bộ kit này?

Xem `CONTRIBUTING.md` — cấu trúc plugin, cách chạy bộ eval, và những ràng buộc môi trường cần biết trước khi sửa.
