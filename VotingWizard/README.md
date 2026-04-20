# VotingWizard

**VotingWizard** — это простая и удобная Ruby-библиотека (gem) для создания опросов и систем голосования.
Она позволяет создавать опросы, добавлять варианты ответов, принимать голоса и вычислять результаты.

---

## ✨ Возможности

* Создание опросов
* Добавление вариантов ответа
* Голосование пользователей
* Защита от повторного голосования
* Подсчёт результатов
* Определение победителя
* Расчёт процентов голосов

---

## 📦 Установка

Добавьте в ваш `Gemfile`:

```ruby
gem "voting_wizard"
```

Затем выполните:

```bash
bundle install
```

Или установите напрямую:

```bash
gem install voting_wizard
```

---

## 🚀 Использование

```ruby
require "voting_wizard"

poll = VotingWizard::Poll.new("Любимый язык программирования?")

poll.add_option("Ruby")
poll.add_option("Python")
poll.add_option("Go")

poll.vote(user: "Ivan", option: "Ruby")
poll.vote(user: "Maria", option: "Python")
poll.vote(user: "Alex", option: "Ruby")

puts poll.results
# => { "Ruby" => 2, "Python" => 1, "Go" => 0 }

puts poll.winner
# => "Ruby"

puts poll.percentage_for("Ruby")
# => 66.67
```

---

## 💻 CLI

После установки gem можно запустить интерактивный режим:

```bash
voting_wizard
```

Или сразу передать вопрос и варианты через аргументы:

```bash
voting_wizard --question "Favorite language?" --option Ruby --option Python --option Go
```

В CLI доступны действия:

* добавление нового варианта
* голосование пользователя
* просмотр результатов
* просмотр победителя
* сохранение результатов в `txt`, `json` или `csv`
* выход из программы

Пример сохранения результатов:

1. выберите пункт `5` в меню
2. укажите путь, например `results.json` или `results.csv`
3. CLI сохранит текущие результаты голосования в файл

---

## 📚 API

### Создание опроса

```ruby
poll = VotingWizard::Poll.new("Вопрос?")
```

---

### Добавление вариантов

```ruby
poll.add_option("Вариант 1")
poll.add_option("Вариант 2")
```

---

### Голосование

```ruby
poll.vote(user: "username", option: "Вариант 1")
```

---

### Получение результатов

```ruby
poll.results
# => { "Вариант 1" => 2, "Вариант 2" => 1 }
```

---

### Определение победителя

```ruby
poll.winner
# => "Вариант 1"
```

---

### Процент голосов

```ruby
poll.percentage_for("Вариант 1")
# => 66.67
```

---

### Общее количество голосов

```ruby
poll.total_votes
```

---

## ⚠️ Обработка ошибок

Библиотека выбрасывает ошибки в следующих случаях:

* `VotingWizard::DuplicateOptionError` — вариант уже существует
* `VotingWizard::DuplicateVoteError` — пользователь уже голосовал
* `VotingWizard::OptionNotFoundError` — вариант не найден
* `VotingWizard::InvalidOptionError` — некорректный вариант
* `VotingWizard::InvalidUserError` — некорректный пользователь

---

## 🧪 Запуск тестов

```bash
bundle exec rspec
```

---

## ⚙️ CI/CD

Проект использует GitHub Actions для автоматического запуска тестов при каждом `push` и `pull request`.

---

## 📁 Структура проекта

```text
lib/
  voting_wizard.rb
  voting_wizard/
    poll.rb
    option.rb
    vote.rb
    error.rb
spec/
```

---


## 📄 Лицензия

Проект распространяется под лицензией MIT.
