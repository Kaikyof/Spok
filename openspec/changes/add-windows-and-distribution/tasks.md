## 1. Windows

- [ ] 1.1 `flutter create --platforms=windows .`, заголовок и иконка; сборка на живой машине; `AppPaths` проверен на Windows (тест раскладки уже есть — прогнать на Windows в CI)
- [ ] 1.2 `SecretStore` через Credential Manager (`win32`), запасной файл 0600; тесты «секрет на Windows», «Windows без Credential Manager»
- [ ] 1.3 `ExecutableLocator`: `.cmd`/`.exe`, `where` вместо `which`; тест
- [ ] 1.4 CI: `windows.yml` и `macos.yml` (analyze, test, build) — матрица; тест «PR ломает только Windows» проверить нарочно испорченной веткой

## 2. Linux

- [ ] 2.1 Прогон на живой Linux-машине: GUI, gnome-keyring, `xdg-open`; зафиксировать результат в `docs/ru/`; исправления по итогам
- [ ] 2.2 AppImage в workflow релиза; Flatpak — задача второй очереди в `ROADMAP.md`

## 3. Релиз

- [ ] 3.1 `release.yml` по тегу `v*`: три сборки, артефакты в GitHub Releases, описание из `CHANGELOG.md`; тест «тег v0.2.0» на пробном теге в форке
- [ ] 3.2 macOS: `codesign` + `notarytool` с секретами в GitHub Secrets, `.dmg`; cask в `homebrew-spok`; проверка первого запуска без предупреждения; удалить `scripts/build_dmg.sh`
- [ ] 3.3 Windows: MSIX через пакет `msix` с самоподписью, честное описание в README
- [ ] 3.4 «Проверить обновления» в «О приложении» через GitHub Releases; тесты «есть новая версия», «без действия человека»
