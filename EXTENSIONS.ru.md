# Дополнения общего API v2

Версия доступна как `api.version == 2`. Новые функции добавлены к существующим модулям; старые сигнатуры работают. Векторы — обычные таблицы `{x,y,z}` / `{x,y}`, цвет — четыре целых канала `{r,g,b,a}` от 0 до 255.

## Графика

Все функции рисования, загрузка ресурсов, работа с пользовательскими шрифтами и координатами меню доступны только из `paint`. Сохраняй полученные handles в локальных переменных скрипта. Не загружай изображение или шрифт заново каждый кадр.

| Вызов | Описание |
|---|---|
| `render.screen_size()` | Два результата: width, height в пикселях; аналог `client.screen_size` |
| `render.frame_time()` | Время последнего кадра в секундах, как `client.frametime` |
| `render.frame_count()` | Число вызовов Lua paint с инициализации DLL; не simulation tick и не engine framecount |
| `render.rect_filled_fade(x,y,w,h,tl,tr,br,bl)` | Прямоугольник с четырьмя цветами: верхний левый, верхний правый, нижний правый, нижний левый |
| `render.poly_line(points,color[,thickness=1[,closed=false]])` | 2..256 `{x,y}`, толщина 0.1..100 |
| `render.polygon(points,color)` | Заливка простого выпуклого или вогнутого полигона, 3..256 вершин |
| `render.concave_polygon(points,color)` | Та же реализация, явное имя для вогнутого полигона |
| `render.arc(x,y,radius,start_angle,end_angle,color[,thickness=1[,segments=64]])` | Дуга; углы в радианах, segments целое 2..256, radius 0..10000 |
| `render.circle_fade(x,y,radius,inside,outside)` | Радиальный градиент от центра до края, 64 сегмента |
| `render.circle_3d(position,radius,color[,normal])` | Контур окружности в мировом пространстве, 64 сегмента, толщина 1 px |
| `render.circle_filled_3d(position,radius,color[,normal])` | Заливка мировой окружности |
| `render.circle_fade_3d(position,radius,inside,outside[,normal])` | Радиальный градиент мировой окружности |
| `render.push_clip_rect(x,y,w,h)` | Добавить пересекающуюся область обрезки, до 16 уровней |
| `render.pop_clip_rect()` | Убрать один уровень, добавленный текущим callback |

Для 3D-окружностей `normal` по умолчанию `{x=0,y=0,z=1}`: окружность лежит горизонтально. Ненулевой вектор нормализуется. Сегменты, пересекающие ближнюю плоскость, пропускаются; это 2D overlay, без глубинного теста и окклюзии стенами. При отсутствии камеры ничего не рисуется.

Полигоны: вершины по контуру, любое направление обхода, без отверстий, самопересечений и повторной замыкающей вершины. Некорректный/вырожденный контур может вызвать ошибку. Поддержка произвольных самопересекающихся контуров не заявляется. Заливка триангулируется без сглаживания границ.

Область clip действует только до конца текущего callback. Даже при ошибке незакрытые уровни снимаются, чтобы следующий скрипт не наследовал обрезку. Нельзя снимать clip другого скрипта или native renderer.

Показатели screen/frame доступны и вне `paint`; остальные функции таблицы рисуют только в `paint`. Используй `render.rect(...,true)` и `render.circle(...,true)` для обычной заливки, как в API v1.

## Музыка и звуки

`audio.play(basename[, loop=false]) -> ok, error` воспроизводит MP3 из `%LOCALAPPDATA%\skeet\muzon`. Передавай только имя файла, например `"track.mp3"`; абсолютные пути, подпапки и ссылки не принимаются. `loop=true` повторяет трек. Каждый скрипт управляет своим воспроизведением; повторный `play` заменяет предыдущий трек этого скрипта.

`audio.volume(percent) -> ok` меняет громкость текущего трека этого скрипта в диапазоне `0..100`. `audio.stop()` останавливает его. При выключении или ошибке скрипта воспроизведение автоматически прекращается. Все три вызова используют штатное мультимедийное устройство Windows; успешность декодирования конкретного MP3 зависит от него. Пример с переключателем и слайдером: [Vakhtang Zimmer - Nano Lezginka.lua](examples/Vakhtang%20Zimmer%20-%20Nano%20Lezginka.lua).

Файл должен быть обычным MP3 размером от 256 байт до 256 MiB. Если файл отсутствует, слишком мал или Windows не смогла его открыть, `audio.play` возвращает `false` и текст ошибки вторым результатом. `audio.volume` возвращает `false`, если у этого скрипта нет открытого трека или устройство не приняло изменение громкости. После замены неисправного MP3 выключи и снова включи переключатель скрипта, чтобы повторить запуск. Указанный для примера файл `Hotline Kavkaz (Confirmed Soundtrack) - Vakhtang Zimmer - Nano Lezginka.mp3` должен лежать непосредственно в `muzon`.

```lua
local ok, err = audio.play("track.mp3", true)
if ok then
    audio.volume(50)
else
    client.log(err)
end
events.on("shutdown", function() audio.stop() end)
```

## Текстуры и шрифты

Файлы ресурсов располагаются в `%LOCALAPPDATA%\skeet\resources` (в общем случае `config_dir/resources`). Создай эту папку и положи туда PNG/JPEG/TTF/OTF. Для текстур также доступна папка `%LOCALAPPDATA%\skeet\skeetles`: передай `"skeetles/имя.png"` в `render.setup_texture`. Остальные подпапки, абсолютные пути, `..`, ссылки/reparse points не разрешены. Файл: от 1 байта до 4 MiB. Это отдельные файлы, они не включаются в конфиг.

### `render.setup_texture(basename) -> handle | nil, reason`

Декодирует изображение средствами существующего WIC-загрузчика, например `"logo.png"` из `config_dir/resources/logo.png` или `"skeetles/overlay.png"` из `config_dir/skeetles/overlay.png`. При ожидаемой ошибке загрузки возвращает `nil, reason`; неправильное имя, тип аргумента или запрещённый путь вызывают ошибку API.

### `render.setup_texture_from_memory(bytes) -> handle | nil, reason`

`bytes` — бинарная Lua-строка с **закодированным** изображением, максимум 4 MiB. Массив чисел сюда напрямую не подходит; для небольшого буфера используй `string.char(...)`/`table.concat`.

### `render.setup_texture_rgba(bytes,width,height) -> handle | nil, reason`

`bytes` — бинарная строка с каналами R,G,B,A каждого пикселя, строки сверху вниз. Ровно `width*height*4` байт, без padding. Размеры целые 1..4096, до 1 048 576 пикселей на изображение. Неверная длина/размер вызывает ошибку.

```lua
local texture
events.on("paint", function()
    if not texture then
        texture = render.setup_texture_rgba(string.char(255, 80, 30, 255), 1, 1)
    end
    if texture then render.texture(texture, 30, 30, 100, 50) end
end)
```

### `render.texture(handle,x,y,width,height[,tint[,rounding=0]])`

Рисует изображение; tint по умолчанию белый `{255,255,255,255}`, rounding от 0 до 1000 пикселей. Width/height — размеры, не правая нижняя координата.

### `render.texture_size(handle) -> width, height`

Возвращает исходные размеры загруженного изображения в пикселях. В `paint` можно передать их в `render.texture`, чтобы не искажать пропорции. Handle должен принадлежать текущему скрипту.

### `render.texture_rotated(handle,center_x,center_y,width,height,angle[,tint])`

Рисует изображение с поворотом вокруг указанного центра. Угол задаётся в радианах, положительное значение вращает по часовой стрелке на экране. Размеры задаются отдельно; для сохранения пропорций используй `render.texture_size`. Вызывай в `paint`. Например, `render.texture_rotated(image, x + w/2, y + h/2, w, h, client.time() * speed * 2 * math.pi)` делает `speed` оборотов в секунду.

### `render.setup_font(basename,size) -> handle | nil, reason`

Шрифт TTF/OTF из `config_dir/resources/<basename>` (обычно `%LOCALAPPDATA%\skeet\resources\<basename>`), size 6..96 пикселей. Для папки `%LOCALAPPDATA%\skeet\fonts` передай `"fonts/<basename>"`. При отсутствующем файле, неуспешной загрузке или исчерпанном кэше возвращает `nil, reason`. Стиль/размер задаются отдельным ресурсом; аргумента flags нет.

### `render.text(x,y,text,color[,font])`

Новый пятый аргумент выбирает шрифт, созданный этим скриптом. Без аргумента прежний шрифт renderer.

### `render.measure_text(text[,font]) -> width,height`

Измерение указанным шрифтом. С пользовательским шрифтом требуется `paint`; без него сохранено прежнее поведение.

Ресурсы кэшируются по содержимому в пределах сессии DLL: до 64 разных текстур, суммарно 8 388 608 пикселей, 16 шрифтов/размеров, 32 MiB исходных байтов. GPU-расход и атласы шрифтов больше исходных файлов. Одинаковый ресурс при reload использует кэш. Изменённый файл занимает новую запись. При исчерпании лимита загрузчик возвращает `nil, reason`, позволяя оставить прежний handle или стандартный шрифт; автоматического вытеснения/удаления нет.

### Ошибки загрузки ресурсов

Успешный вызов возвращает handle; второй результат при присваивании равен `nil`. Прежний код с одним результатом работает. Ошибка загрузки возвращает два результата: `nil` и строковый код:

| Код | Причина |
|---|---|
| `config_directory_unavailable`, `resource_directory_unavailable` | Нет каталога конфигурации или нужной папки ресурсов |
| `file_not_found`, `file_open_failed` | Нет файла либо Windows отказала в открытии |
| `file_info_failed`, `file_read_failed` | Не удалось прочитать метаданные или все байты файла |
| `file_size_limit` | Файл пуст либо больше 4 MiB |
| `font_limit`, `texture_limit`, `resource_bytes_limit` | Исчерпан соответствующий общий кэш сессии |
| `texture_pixel_limit` | Не хватает лимита пикселей для RGBA-текстуры или кэш уже заполнен |
| `font_load_failed` | Загрузчик шрифтов отверг данные |
| `texture_load_failed` | WIC-загрузка, допустимые размеры или создание GPU-ресурса не прошли; этот загрузчик не различает причины |
| `gpu_create_failed` | Не удалось создать GPU-ресурс из RGBA-буфера |

Неверные аргументы, запрещённые пути и ссылки/reparse points остаются ошибками API. Бюджет исполнения и память Lua имеют отдельные ограничения.

```lua
local font, attempted
events.on("paint", function()
    if not attempted then
        attempted = true
        local reason
        font, reason = render.setup_font("Excalifont-Regular.ttf", 18)
        if not font then client.log_level("warning", "Font:", reason) end
    end
    render.text(40, 40, "Text with fallback", {255,255,255,255}, font)
end)
```

## Защищённые вызовы и диагностика

`api.protect(fn[, limits]) -> ok, error, ...results` вызывает функцию без аргументов. При успехе возвращает `true, nil` и все её результаты, включая промежуточные/последние `nil`. При обычной Lua-ошибке или ошибке аргументов API возвращает `false, traceback`. Для передачи аргументов используй замыкание. Выполненные изменения настроек, рисование и другие действия не откатываются.

По умолчанию вложенный вызов ограничен 50 000 инструкций и 2 ms. В `limits` разрешены только `instructions` (целое 1000..2 000 000) и `time_ms` (больше 0, не больше 25). До восьми вложенных вызовов. Каждый вызов расходует общий бюджет callback; более широкий вложенный лимит не расширяет родительский. Счётчик инструкций приблизительный, с шагом 1000. Бюджет времени проверяется также при возвращении из native API и `api.protect`; native-вызов нельзя прервать посередине. Как и раньше, ожидание Windows audio не входит в измеряемое время исполнения.

**Превышение любого бюджета и ошибки выделения памяти остаются фатальными:** `api.protect` не возвращает их как обычную ошибку; скрипт отключается. `pcall`/`xpcall` по-прежнему отсутствуют.

```lua
local ok, err, result = api.protect(function()
    return settings.get("ragebot", "enabled")
end, {instructions = 50000, time_ms = 2})
if ok then client.log("Ragebot:", result)
else client.log_level("warning", err) end
```

`client.log(...)` и `print(...)` сохраняют прежние аргументы и пишут с уровнем `info`. `client.log_level(level, ...)` принимает `debug`, `info`, `warning`, `error`; уровень виден в строке журнала. Редактор хранит последние 1000 строк, фильтры **Only this script** и **Minimum level** применяются к показу и **Copy log**. **Clear log** очищает общий журнал.

`client.stats()` возвращает состояние текущего исполнения: `phase`, приблизительное `instructions`, `api_calls` (включая сам запрос статистики), `native_work` (API-вызовы и обход таблиц), `time_ms`, `memory_bytes`. Это прошедшее время с исключением ожиданий audio, а не CPU/GPU-профиль; память относится только к Lua allocator. `last` содержит те же показатели предыдущего завершённого исполнения либо `nil`. `invocations` считает завершённые загрузку/callbacks, `protected_errors` — обычные ошибки, обработанные через `api.protect`. Оба счётчика живут до отключения/перезагрузки экземпляра.

Кэш удерживает ресурсы после выгрузки Lua, поскольку draw commands текущего кадра сохраняют указатели на них. Числовые handles принадлежат загруженному экземпляру скрипта: после reload получи их снова, не сохраняй в storage/конфиге и не передавай другому Lua. Вызовы загрузки могут быть дорогими; выполняй один раз, без циклического создания новых ресурсов.

## Меню и жизненный цикл

- `ui.is_menu_opened() -> boolean`: состояние главного меню, только `paint`.
- `ui.get_menu_rect() -> {x,y,w,h}`: прямоугольник главного меню в пикселях, только `paint`; это не окно Lua.
- `client.unload()`: запросить выгрузку **своего** скрипта после выхода из callback. Последующие callbacks этого прохода не исполняются. Сам callback продолжает выполняться до return. При обычной выгрузке вызывается `shutdown`, overrides снимаются, UI удаляется, storage сохраняется. Для прекращения кода пиши `client.unload(); return`.

## Математика

Стандартная библиотека `math` сохранена; добавлены:

| Вызов | Результат |
|---|---|
| `math.calc_angle(src,dst)` | Углы `{x,y,z}` от src к dst |
| `math.calc_fov(src_angles,dst_angles)` | Угловое расстояние по штатному helper, в градусах |
| `math.normalize_angle(degrees)` | Число в `[-180,180]`; обе граничные формы допустимы |
| `math.vector_angles(forward)` | Углы направления |
| `math.angle_vectors(angles)` | Три результата `{x,y,z}`: forward, **right**, up |

Данные углов передаются как `{x=pitch,y=yaw,z=roll}`. Нулевое направление не определяет полезную цель, проверяй расстояние перед наведением. Поворот/вычитание векторов в Lua выполняются по компонентам: метаметодов `vec3_t` нет.

## Combat

Дополнения работают в обычных командных callbacks (`pre_rage`, `create_move` и т.д.), не в `paint` и не во внутренних `rage_*` callbacks.

### `combat.hitboxes(id[,record_tick]) -> snapshot | nil`

Берёт последнюю доступную не-future запись или запись с указанным tick. Ответ: `{tick,time,hitboxes}`. Поля каждого хитбокса:

- `index`, `bone`, `radius`;
- `mins`, `maxs` в локальной системе хитбокса;
- `center`, `capsule_a`, `capsule_b` в мировых координатах;
- `rotation={x,y,z,w}` — quaternion кости.

Недоступная/устаревшая запись даёт `nil`. Снимок не меняет engine pose и не является живой ссылкой. Bone index и hitbox index различаются.

### `combat.damage(id,position[,record_tick]) -> result | nil`

Возвращает `{damage,hitbox,hitgroup,penetrated}`. Дополнительный tick задаёт доступную историческую позу; без него остаётся прежняя текущая поза. Если конкретная запись исчезла, функция вернёт `nil`, а не молча переключится на другую. Точка должна соответствовать позе, которую проверяешь.

### `combat.hitchance(id,position,hitbox[,record_tick]) -> percent | nil`

Геометрическая оценка 0..100 по штатному sampler, текущим eye/inaccuracy/spread и выбранному хитбоксу записи. Без tick используется последняя доступная запись. `nil`, если цель/запись/хитбокс недоступны. Эта функция не выполняет penetration и не подменяет оценку на 100 при включённом no-spread; проверку урона делай отдельно.

До 32 запросов на скрипт/команду суммарно с `ragebot.hitchance`. Нельзя применять будущую подготовительную запись для выстрела. Срок жизни record tick короткий: проверяй доступность каждый вызов.

Примеры расширений: [graphics_v2.lua](examples/graphics_v2.lua), [rage_patterns.lua](examples/rage_patterns.lua), [rage_selection.lua](examples/rage_selection.lua), [rage_custom_command.lua](examples/rage_custom_command.lua).
